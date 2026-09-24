import { Boom } from "@hapi/boom";
import makeWASocket, {
  DisconnectReason,
  fetchLatestBaileysVersion,
  isLidUser,
  useMultiFileAuthState,
  type WASocket,
  type WAMessageKey,
  proto,
} from "@whiskeysockets/baileys";
import fs from "node:fs";
import path from "node:path";
import qrcodeTerminal from "qrcode-terminal";
import { config, isPhoneAllowed } from "./config.js";
import { createLogger } from "./logger.js";
import * as sessionStore from "./sessionStore.js";
import { extractText, jidToPhone, relayToAgent, relayHistoryToAgent, type HistoryMessage } from "./messageHandler.js";

const log = createLogger("baileys-service");

let sock: WASocket | null = null;
let latestQr: string | null = null;
// Tracks when the current QR actually expires, per Baileys' own generateAndEmitQR
// timing (src/Socket/socket.ts): the first QR of a connect() cycle lives 60s, every
// QR after that lives 20s, unless the `qrTimeout` socket option overrides both — we
// leave it unset, so these are the real, in-effect defaults. qrEmitCount resets each
// time connect() runs so a fresh cycle again gets the longer first-QR window.
let latestQrExpiresAt: number | null = null;
let qrEmitCount = 0;
const FIRST_QR_TTL_MS = 60_000;
const SUBSEQUENT_QR_TTL_MS = 20_000;
let reconnectAttempts = 0;
const MAX_RECONNECT_ATTEMPTS = 10;

// Set by shutdown() so the connection.update "close" handler below skips its
// normal reconnect/logout bookkeeping — a deliberate shutdown() close should
// never be mistaken for WhatsApp reporting a real disconnect.
let shuttingDown = false;

// Credentials are NEVER cleared automatically by this service, not even on a
// confirmed WhatsApp logout — a past incident lost a paired session when a
// transient connection error was misclassified as a logout and auto-wiped
// the stored creds, forcing an in-person re-pair. If WhatsApp reports a real
// logout, reconnecting with the same (now server-invalid) creds will just
// report the same logout again; past this cap we stop retrying and leave the
// process idle, waiting for a human to decide whether to manually clear
// sessionStore's credentials (see clearCredentials) and re-pair via QR.
let consecutiveLogouts = 0;
const MAX_CONSECUTIVE_LOGOUTS = 3;

/** In-memory only — LID privacy-mode addresses resolved to real phone JIDs. */
const lidToPhone = new Map<string, string>();

// This account's own WhatsApp-reported number, set once the socket reports
// connection === "open". Sent up with every relayToAgent call so Postgres's
// shared whatsapp_messages table (one table, multiple accounts) can tell
// which paired account a captured message belongs to.
let connectedPhone: string | null = null;

/** In-memory LRU cache of recent messages for answering WhatsApp retry/decryption requests (getMessage). */
const MAX_MESSAGE_CACHE = 1000;
const messageCache = new Map<string, proto.IMessage>();

function cacheMessage(id: string | null | undefined, message: proto.IMessage | null | undefined): void {
  if (!id || !message) return;
  messageCache.set(id, message);
  if (messageCache.size > MAX_MESSAGE_CACHE) {
    const oldest = messageCache.keys().next().value;
    if (oldest !== undefined) messageCache.delete(oldest);
  }
}

// Message IDs our own sendText() just sent, so the messages.upsert handler
// (which also sees fromMe:true events for our own outgoing sends) can tell
// "the bot sent this" apart from "a human typed this directly in WhatsApp
// Business" — the former is already logged via relayToAgent's normal reply
// flow, so re-logging it in the fromMe branch would duplicate the row.
// Capped so a send whose upsert event never arrives can't leak memory.
const sentMessageIds = new Set<string>();
const MAX_TRACKED_SENT_IDS = 500;
function rememberSentId(id: string | null | undefined): void {
  if (!id) return;
  sentMessageIds.add(id);
  if (sentMessageIds.size > MAX_TRACKED_SENT_IDS) {
    const oldest = sentMessageIds.values().next().value;
    if (oldest !== undefined) sentMessageIds.delete(oldest);
  }
}

// In-memory only, rebuilt from WhatsApp's own app-state sync on every connect
// (labels.edit fires once per existing label on a fresh sync, then again on
// any create/rename/delete while connected) — labelId -> current name. Labels
// are created by hand in the WhatsApp Business app (see labelChat below), not
// by this bridge, so there's nothing to persist here.
const labelsById = new Map<string, string>();

/** Serial, rate-limited outbound queue so we never trip WhatsApp's anti-spam limits. */
class SendQueue {
  private queue: Array<() => Promise<void>> = [];
  private running = false;
  private lastSendAt = 0;

  enqueue(task: () => Promise<void>): void {
    this.queue.push(task);
    void this.drain();
  }

  private async drain(): Promise<void> {
    if (this.running) return;
    this.running = true;
    while (this.queue.length > 0) {
      const task = this.queue.shift()!;
      const wait = config.minSendIntervalMs - (Date.now() - this.lastSendAt);
      if (wait > 0) await new Promise((r) => setTimeout(r, wait));
      try {
        await task();
      } catch (err) {
        log.error({ err }, "Send task failed");
      }
      this.lastSendAt = Date.now();
    }
    this.running = false;
  }
}

const sendQueue = new SendQueue();

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function randomBetween(min: number, max: number): number {
  return min + Math.random() * (max - min);
}

/** Roughly how long a person would take to type this reply, clamped to a plausible range. */
function typingDelayMs(text: string): number {
  const raw = text.length * config.typingMsPerChar;
  return Math.min(config.maxTypingDelayMs, Math.max(config.minTypingDelayMs, raw));
}

function touchHealthFile(): void {
  fs.writeFile(config.healthFile, String(Date.now()), () => {});
}

async function restoreAuthFromDb(): Promise<void> {
  if (fs.existsSync(config.authDir)) {
    const diskFiles = fs.readdirSync(config.authDir).filter((f) => f.endsWith(".json"));
    if (diskFiles.length > 0) {
      log.info({ count: diskFiles.length }, "Auth state already present on volume disk — preserving live keys");
      await persistAuthToDb();
      return;
    }
  }
  const creds = await sessionStore.loadCredentials();
  if (!creds) return;
  fs.mkdirSync(config.authDir, { recursive: true });
  const parsed = JSON.parse(creds) as Record<string, string>;
  for (const [filename, content] of Object.entries(parsed)) {
    fs.writeFileSync(path.join(config.authDir, filename), content, "utf8");
  }
  log.info("Restored auth state from Postgres");
}

async function persistAuthToDb(): Promise<void> {
  if (!fs.existsSync(config.authDir)) return;
  const files = fs.readdirSync(config.authDir).filter((f) => f.endsWith(".json"));
  const bundle: Record<string, string> = {};
  for (const f of files) {
    bundle[f] = fs.readFileSync(path.join(config.authDir, f), "utf8");
  }
  await sessionStore.saveCredentials(JSON.stringify(bundle));
}

let lastAlertSentAt = 0;
async function notifyAdminOfDisconnect(reason: string): Promise<void> {
  if (Date.now() - lastAlertSentAt < 10 * 60 * 1000) return;
  lastAlertSentAt = Date.now();
  const alertPhone = "+50663314801";
  const pilotUrl = "http://mb-baileys-bridge-new:8766/send?token=656737e23371f29c9be3f13089c931b52b26872f";
  try {
    const alertText = "🚨 *ALERTA MONKEY BOX*: El WhatsApp oficial (+506 7157-5607) se ha desconectado.\n\nMotivo: " + reason + "\n\nRe-vincular aquí: https://monkeybox.avantia.space/pair?token=XJmfgBjm1kv_biINo6yOLhd5bxJg3nX0KAJbhSYme2g";
    await fetch(pilotUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ phone: alertPhone, text: alertText }),
    });
    log.info({ alertPhone }, "Sent disconnect alert to admin WhatsApp");
  } catch (err) {
    log.warn({ err }, "Failed to send disconnect alert via pilot bridge");
  }
}

// Safety net: periodically back up any newly generated pre-keys to Postgres
setInterval(() => {
  if (sock && !shuttingDown) {
    persistAuthToDb().catch((err) => log.warn({ err }, "Periodic auth persist failed"));
  }
}, 5 * 60 * 1000);

export async function startBaileys(): Promise<void> {
  await restoreAuthFromDb();
  fs.mkdirSync(config.authDir, { recursive: true });
  await connect();
}

async function connect(): Promise<void> {
  qrEmitCount = 0;
  const { state, saveCreds } = await useMultiFileAuthState(config.authDir);
  const { version } = await fetchLatestBaileysVersion();

  sock = makeWASocket({
    version,
    auth: state,
    logger: createLogger("baileys-socket") as any,
    printQRInTerminal: false,
    // Business Terminal identification: identifies as an in-store terminal instead of suspicious Mac/Desktop
    browser: ["MonkeyBox Terminal", "Chrome", "122.0.0"],
    // true so a *fresh* QR pairing (never a reconnect of an already-paired
    // session — see messaging-history.set below) gets WhatsApp's one-time
    // pre-existing chat history instead of starting the Postgres transcript
    // blank from that moment on.
    syncFullHistory: true,
    // Baileys defaults this to true, which marks the linked-device session as
    // "online" — WhatsApp then suppresses push notifications on the phone for
    // messages it thinks you already saw on the online device. Keeping this
    // false, plus sending an explicit "unavailable" presence right after
    // connecting below, keeps the phone's own notifications working normally
    // while this bridge stays connected in the background.
    markOnlineOnConnect: false,
    // Hardening: answers WhatsApp enc-retry-requests to prevent session invalidation
    getMessage: async (key: WAMessageKey) => {
      if (key.id && messageCache.has(key.id)) {
        return messageCache.get(key.id);
      }
      return proto.Message.fromObject({});
    },
  });

  sock.ev.on("creds.update", async () => {
    await saveCreds();
    await persistAuthToDb();
  });

  sock.ev.on("labels.edit", (label) => {
    if (label.deleted) {
      labelsById.delete(label.id);
    } else {
      labelsById.set(label.id, label.name);
    }
  });

  sock.ev.on("connection.update", async (update) => {
    const { connection, lastDisconnect, qr } = update;

    if (qr) {
      qrEmitCount += 1;
      latestQr = qr;
      latestQrExpiresAt = Date.now() + (qrEmitCount === 1 ? FIRST_QR_TTL_MS : SUBSEQUENT_QR_TTL_MS);
      await sessionStore.setStatus("pairing");
      log.info("New QR code — scan it below, or fetch GET /qr for a PNG");
      qrcodeTerminal.generate(qr, { small: true });
    }

    if (connection === "open") {
      reconnectAttempts = 0;
      consecutiveLogouts = 0;
      latestQr = null;
      latestQrExpiresAt = null;
      const phone = sock?.user?.id ? jidToPhone(sock.user.id) : null;
      connectedPhone = phone;
      await sessionStore.setStatus("connected", phone ?? undefined);
      log.info({ phone }, "WhatsApp connected");
      await persistAuthToDb();
      try {
        await sock?.sendPresenceUpdate("unavailable");
      } catch (err) {
        log.warn({ err }, "Failed to set initial unavailable presence");
      }
    }

    if (connection === "close") {
      if (shuttingDown) {
        log.info("Socket closed for process shutdown — skipping reconnect/logout bookkeeping");
        touchHealthFile();
        return;
      }

      const statusCode = (lastDisconnect?.error as Boom | undefined)?.output?.statusCode;
      const loggedOut = statusCode === DisconnectReason.loggedOut;
      const restartRequired = statusCode === DisconnectReason.restartRequired;

      if (restartRequired) {
        // Expected step right after a successful QR scan, not a failure:
        // WhatsApp forces this disconnect so Baileys can reopen the socket
        // with the now-registered credentials. Reconnect immediately, with
        // no backoff and without touching reconnectAttempts/consecutiveLogouts
        // — those counters are for real connection problems, and delaying
        // this step by the same backoff used for those is what made pairing
        // feel stuck/slow and could plausibly surface as a phone-side error.
        latestQr = null;
        latestQrExpiresAt = null;
        await sessionStore.setStatus("connecting");
        log.info("QR scanned — finishing pairing handshake");
        void connect();
        return;
      }

      await sessionStore.setStatus("disconnected");

      if (loggedOut) {
        consecutiveLogouts += 1;
        const errStr = JSON.stringify(lastDisconnect?.error ?? "");
        const isDeviceRemoved = errStr.includes("device_removed");
        log.error(
          { consecutiveLogouts, statusCode, isDeviceRemoved },
          "WhatsApp reported a logout — credentials are left untouched by design; " +
            "if this is a genuine logout, a human must manually clear them via sessionStore.clearCredentials() and re-pair via QR"
        );

        if (isDeviceRemoved) { void notifyAdminOfDisconnect("Dispositivo desvinculado desde el teléfono físico (device_removed)"); }

        if (consecutiveLogouts > MAX_CONSECUTIVE_LOGOUTS) {
          log.error(
            { consecutiveLogouts },
            "Repeated logout on reconnect — stopping auto-reconnect to avoid hammering WhatsApp's servers; needs manual intervention"
          );
          void notifyAdminOfDisconnect("Sesión cerrada o invalidada por WhatsApp (401 recurrente)");
          return;
        }

        const delay = Math.min(30_000, 1000 * 2 ** consecutiveLogouts);
        log.warn({ delay, consecutiveLogouts }, "Retrying connect after logout, credentials untouched");
        setTimeout(() => void connect(), delay);
        return;
      }

      consecutiveLogouts = 0;

      if (reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
        reconnectAttempts += 1;
        const delay = Math.min(30_000, 1000 * 2 ** reconnectAttempts);
        log.warn({ delay, attempt: reconnectAttempts }, "Reconnecting");
        setTimeout(() => void connect(), delay);
      } else {
        log.error("Max reconnect attempts reached — process will exit for container restart");
        process.exit(1);
      }
    }

    touchHealthFile();
  });

  const currentSock = sock;

  sock.ev.on("messaging-history.set", async ({ messages: historyMessages }) => {
    // Fires at most once per connect() cycle, and only ever carries anything
    // on a genuinely fresh QR pairing — Baileys skips history-sync entirely
    // on a reconnect of an already-paired session. Every message here
    // predates this bridge's own existence on the account, so it always
    // goes through relayHistoryToAgent (never relayToAgent/handle_message):
    // nothing in a history batch can trigger a reply, an escalation, or a
    // label. Intentionally re-derives the sender phone with the same
    // LID-aware logic as the live messages.upsert handler below rather than
    // sharing a helper — this handler only ever runs once per pairing, so
    // the small duplication is worth not touching the already-tested live
    // path for this.
    const batch: HistoryMessage[] = [];
    for (const m of historyMessages) {
      if (!m.message) continue;
      const rawJid = m.key.participant ?? m.key.remoteJid;
      const altJid = m.key.participantAlt ?? m.key.remoteJidAlt;
      let jid = altJid ?? rawJid;
      if (!jid || jid.endsWith("@g.us") || jid === "status@broadcast") continue;
      if (!altJid && isLidUser(jid)) {
        const resolvedPn = await currentSock.signalRepository.lidMapping.getPNForLID(jid);
        if (resolvedPn) jid = resolvedPn;
      }
      const text = extractText(m.message);
      if (!text) continue;
      batch.push({
        from_phone: jidToPhone(jid),
        // fromMe here can only mean "sent from the phone's native WhatsApp
        // app before this device was ever linked" — is_human is always
        // correct for these rows, never our own bot (the bot didn't exist
        // yet on this session).
        direction: m.key.fromMe ? "outbound" : "inbound",
        text,
        timestamp: m.messageTimestamp ? Number(m.messageTimestamp) : null,
        wa_message_id: m.key.id ?? null,
      });
    }
    if (batch.length === 0) return;

    const accountPhone = connectedPhone ?? (currentSock.user?.id ? jidToPhone(currentSock.user.id) : null);
    log.info({ count: batch.length }, "Backfilling chat history to Postgres");
    const HISTORY_CHUNK_SIZE = 200;
    for (let i = 0; i < batch.length; i += HISTORY_CHUNK_SIZE) {
      try {
        await relayHistoryToAgent(accountPhone, batch.slice(i, i + HISTORY_CHUNK_SIZE));
      } catch (err) {
        log.error({ err }, "Failed to backfill a history chunk to Postgres");
      }
    }
  });

  sock.ev.on("messages.upsert", async ({ messages, type }) => {
    for (const m of messages) {
      if (m.key.id && m.message) {
        cacheMessage(m.key.id, m.message);
      }
    }
    if (type !== "notify") return;
    for (const m of messages) {
      if (!m.message) continue;

      if (m.key.fromMe) {
        // A message we ourselves sent (fromMe:true) can mean two different
        // things: our own bot reply (already logged via relayToAgent's
        // normal flow — skip it here to avoid a duplicate row), or a staff
        // member typing a reply directly in the WhatsApp Business app (never
        // logged anywhere yet — capture it so the shared table has the full
        // two-sided human-support transcript the client-facing side alone
        // can't show).
        if (m.key.id && sentMessageIds.has(m.key.id)) {
          sentMessageIds.delete(m.key.id);
          continue;
        }
        const rawChatJid = m.key.remoteJid;
        if (!rawChatJid || rawChatJid.endsWith("@g.us") || rawChatJid === "status@broadcast") continue;
        // Same LID-privacy-mode problem as the inbound branch below: remoteJid
        // can be an opaque LID instead of the real phone-number JID. Prefer
        // remoteJidAlt, then fall back to Baileys' own LID<->PN store, before
        // deriving a bogus phone from the bare LID.
        let chatJid = m.key.remoteJidAlt ?? rawChatJid;
        if (!m.key.remoteJidAlt && isLidUser(chatJid)) {
          const resolvedPn = await currentSock.signalRepository.lidMapping.getPNForLID(chatJid);
          if (resolvedPn) chatJid = resolvedPn;
        }
        const humanText = extractText(m.message);
        if (!humanText) continue;
        const humanPhone = jidToPhone(chatJid);
        try {
          await relayToAgent(humanPhone, humanText, {
            accountPhone: connectedPhone,
            humanReply: true,
            standby: config.standby,
          });
        } catch (err) {
          log.error({ err, phone: humanPhone }, "Failed to log human-typed reply to Postgres");
        }
        continue;
      }
      // WhatsApp's LID privacy mode addresses many senders by an opaque LID
      // (e.g. "176226819911687@lid") instead of their phone-number JID. Baileys
      // surfaces the real phone-number JID alongside it in participantAlt /
      // remoteJidAlt — without preferring those, jidToPhone() derives a bogus
      // "+176226819911687" from the LID itself, which never matches
      // BAILEYS_ALLOWED_PHONES and the message is silently dropped.
      const rawJid = m.key.participant ?? m.key.remoteJid;
      const altJid = m.key.participantAlt ?? m.key.remoteJidAlt;
      let jid = altJid ?? rawJid;
      if (!jid || jid.endsWith("@g.us") || jid === "status@broadcast") continue;

      // Alt is only present on a message when Baileys pairs LID+PN on that
      // same stanza (Socket/messages-recv.js). Once a pairing has been
      // learned from an earlier message, later ones addressed by bare LID
      // (no Alt) can still be resolved from Baileys' own persistent
      // LID<->PN store instead of falling back to a bogus phone number.
      if (!altJid && isLidUser(jid)) {
        const resolvedPn = await currentSock.signalRepository.lidMapping.getPNForLID(jid);
        if (resolvedPn) jid = resolvedPn;
      }

      const phone = jidToPhone(jid);

      // Remember the LID this contact was actually addressed by, so replies
      // route back the same way — a phone-number-JID send can fail for a
      // contact WhatsApp only exposes via LID under privacy mode.
      if (rawJid && isLidUser(rawJid)) {
        lidToPhone.set(phone.replace(/[^\d]/g, ""), rawJid);
      }

      const text = extractText(m.message);
      if (!text) continue;

      // BAILEYS_ALLOWED_PHONES only gates whether the agent is allowed to
      // AUTO-REPLY — it must never gate capture. Every inbound message gets
      // logged to Postgres regardless of allowlist membership or standby;
      // passing standby:true to relayToAgent is what tells the webhook not
      // to call handle_message() (see server/main.py), independent of the
      // account's own config.standby value, so this same branch also covers
      // the redundant "standby account, unlisted sender" case.
      if (config.standby || !isPhoneAllowed(phone)) {
        const reason = config.standby ? "standby mode" : "sender not in BAILEYS_ALLOWED_PHONES allowlist";
        log.info({ phone, reason }, "Message captured, no auto-reply");
        try {
          await relayToAgent(phone, text, { accountPhone: connectedPhone, standby: true });
        } catch (err) {
          log.error({ err, phone }, "Failed to log message to Postgres");
        }
        continue;
      }

      await sleep(randomBetween(config.minReadDelayMs, config.maxReadDelayMs));
      await setTyping(phone, true);
      try {
        const { reply, label } = await relayToAgent(phone, text, { accountPhone: connectedPhone });
        if (reply) {
          await sleep(typingDelayMs(reply));
          await sendText(phone, reply);
        }
        if (label) {
          await labelChat(phone, label);
        }
      } catch (err) {
        log.error({ err, phone }, "Failed to relay inbound message to agent");
      } finally {
        await setTyping(phone, false);
      }
    }
    touchHealthFile();
  });
}

/** Shows/hides the "escribiendo..." indicator while the agent generates a reply. */
async function setTyping(phone: string, composing: boolean): Promise<void> {
  if (!sock) return;
  try {
    await sock.sendPresenceUpdate(composing ? "composing" : "paused", phoneToJid(phone));
  } catch (err) {
    log.warn({ err, phone }, "Failed to update typing presence");
  }
}

function phoneToJid(phone: string): string {
  const digits = phone.replace(/[^\d]/g, "");
  const remembered = lidToPhone.get(digits);
  return remembered ?? `${digits}@s.whatsapp.net`;
}

export async function sendText(phone: string, text: string): Promise<void> {
  return new Promise((resolve, reject) => {
    sendQueue.enqueue(async () => {
      if (!sock) throw new Error("Socket not connected");
      try {
        const sent = await sock.sendMessage(phoneToJid(phone), { text });
        rememberSentId(sent?.key?.id);
        if (sent?.key?.id && sent.message) {
          cacheMessage(sent.key.id, sent.message);
        }
        resolve();
      } catch (err) {
        reject(err);
        throw err;
      }
    });
  });
}

export async function sendDocument(
  phone: string,
  url: string,
  filename: string,
  mimetype: string
): Promise<void> {
  return new Promise((resolve, reject) => {
    sendQueue.enqueue(async () => {
      if (!sock) throw new Error("Socket not connected");
      try {
        const sent = await sock.sendMessage(phoneToJid(phone), {
          document: { url },
          mimetype,
          fileName: filename,
        });
        rememberSentId(sent?.key?.id);
        if (sent?.key?.id && sent.message) {
          cacheMessage(sent.key.id, sent.message);
        }
        resolve();
      } catch (err) {
        reject(err);
        throw err;
      }
    });
  });
}

/**
 * Applies a WhatsApp Business chat label to the given contact's chat, by
 * name (case-insensitive) — resolved against whatever labels this account
 * actually has (see labelsById above). Silently no-ops (returns false) if no
 * label with that name exists on this account, so calling it from a bridge
 * that hasn't had the label created yet (e.g. -official, pre-launch) is
 * always safe. The label itself must already exist — created by hand in the
 * WhatsApp Business app — this only ever applies an existing label, never
 * creates one, to avoid silently spawning near-duplicate labels from a typo.
 */
export async function labelChat(phone: string, labelName: string): Promise<boolean> {
  if (!sock) return false;
  const needle = labelName.trim().toLowerCase();
  let labelId: string | null = null;

  // 1. Exact match
  for (const [id, name] of labelsById) {
    if (name.trim().toLowerCase() === needle) {
      labelId = id;
      break;
    }
  }

  // 2. Flexible substring match (e.g. "requiere humano", "humano", "asesor")
  if (!labelId) {
    for (const [id, name] of labelsById) {
      const lower = name.trim().toLowerCase();
      if (lower.includes("humano") || lower.includes("asesor") || needle.includes(lower)) {
        labelId = id;
        break;
      }
    }
  }

  // 3. Auto-create label in WhatsApp Business if it does not exist yet
  if (!labelId) {
    try {
      let maxId = 0;
      for (const idStr of labelsById.keys()) {
        const n = parseInt(idStr, 10);
        if (!isNaN(n) && n > maxId) maxId = n;
      }
      const newId = String(maxId > 0 ? maxId + 1 : 1);
      log.info({ labelName, newId }, "Attempting to create WhatsApp Business label automatically");
      await (sock as any).addLabel("", { id: newId, name: labelName, color: 1, deleted: false });
      labelsById.set(newId, labelName);
      labelId = newId;
    } catch (createErr) {
      log.warn({ createErr, labelName }, "Could not auto-create label (app requires manual label creation on phone)");
    }
  }

  if (!labelId) {
    log.warn(
      { labelName, existingLabels: Array.from(labelsById.values()) },
      "No WhatsApp label matching this name on this account — skipping"
    );
    return false;
  }
  try {
    await sock.addChatLabel(phoneToJid(phone), labelId);
    log.info({ phone, labelName, labelId }, "Successfully applied WhatsApp chat label");
    return true;
  } catch (err) {
    log.warn({ err, phone, labelName }, "Failed to apply chat label");
    return false;
  }
}

export async function requestPairingCode(phone: string): Promise<string> {
  if (!sock) throw new Error("Socket not initialized");
  const digits = phone.replace(/[^\d]/g, "");
  return sock.requestPairingCode(digits);
}

export function getLatestQr(): string | null {
  return latestQr;
}

/** Epoch ms when the current QR actually expires per Baileys' own timing, or null if none is pending. */
export function getLatestQrExpiresAt(): number | null {
  return latestQrExpiresAt;
}

export async function getConnectionStatus() {
  return sessionStore.getStatus();
}

/**
 * Diagnostic only: queries the paired account's own WhatsApp Business profile
 * over the already-live socket (never opens a second connection with the same
 * credentials — that's the exact "stream:error conflict" scenario shutdown()
 * above exists to avoid). Returns null if there's no business profile, which
 * is how Baileys reports a plain (non-Business) WhatsApp account.
 */
export async function getBusinessProfile() {
  if (!sock || !sock.user) return null;
  return sock.getBusinessProfile(sock.user.id);
}

/**
 * Closes the WebSocket cleanly (no logout — credentials stay valid) so
 * WhatsApp's server sees the connection end immediately instead of treating
 * it as still-alive for its own timeout window. Without this, a killed
 * process leaves a stale session on WhatsApp's side that collides with the
 * next process's reconnect attempt (stream:error "conflict"), which can
 * cascade into a real logout — this is what happened on 2026-09-11 when a
 * stack redeploy killed the bridge process with no cleanup. Call this from a
 * SIGTERM/SIGINT handler before the process exits.
 */
export async function resetSession(): Promise<void> {
  log.info("Resetting Baileys session: clearing credentials and reconnecting for fresh pairing");
  consecutiveLogouts = 0;
  reconnectAttempts = 0;
  latestQr = null;
  latestQrExpiresAt = null;
  if (sock) {
    try {
      sock.ev.removeAllListeners("connection.update");
      sock.end(undefined);
    } catch {}
    sock = null;
  }
  if (fs.existsSync(config.authDir)) {
    try {
      const files = fs.readdirSync(config.authDir);
      for (const f of files) {
        try {
          fs.unlinkSync(path.join(config.authDir, f));
        } catch {}
      }
    } catch (err) {
      log.warn({ err }, "Failed to clear auth directory files");
    }
  }
  await sessionStore.clearCredentials();
  await sessionStore.setStatus("disconnected");
  await connect();
}

export function shutdown(): void {
  shuttingDown = true;
  if (!sock) return;
  void persistAuthToDb();
  try {
    sock.end(undefined);
    log.info("Baileys socket closed cleanly for shutdown");
  } catch (err) {
    log.warn({ err }, "Error while closing socket during shutdown");
  }
}
