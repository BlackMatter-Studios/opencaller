import type { proto } from "@whiskeysockets/baileys";
import { config } from "./config.js";
import { createLogger } from "./logger.js";

const log = createLogger("message-handler");

export function extractText(msg: proto.IWebMessageInfo["message"]): string | null {
  if (!msg) return null;
  if (msg.conversation) return msg.conversation;
  if (msg.extendedTextMessage?.text) return msg.extendedTextMessage.text;
  if (msg.imageMessage?.caption) return msg.imageMessage.caption;
  if (msg.videoMessage?.caption) return msg.videoMessage.caption;
  return null;
}

export function jidToPhone(jid: string): string {
  return "+" + jid.split("@")[0].split(":")[0];
}

export interface AgentReply {
  reply: string | null;
  /** WhatsApp Business chat label name the agent wants applied (e.g. an
   *  escalation), or null if this turn didn't trigger one. Resolved to a
   *  labelId and applied by the caller — see baileysService.ts's labelChat. */
  label: string | null;
}

export interface RelayOptions {
  /** This account's own WhatsApp-reported number, so Postgres's shared
   *  whatsapp_messages table can tell which account received the message —
   *  see baileysService.ts's connectedPhone. */
  accountPhone?: string | null;
  /** True when this account is in BAILEYS_STANDBY mode: the message still
   *  gets captured in Postgres, but the agent must not generate or send a
   *  reply for it. */
  standby?: boolean;
  /** True when this call is only logging a message a staff member already
   *  typed directly in the WhatsApp Business app (a fromMe message) — the
   *  agent must log it as an outbound row and otherwise leave it alone:
   *  never call handle_message(), never generate a reply, regardless of the
   *  account's standby state. */
  humanReply?: boolean;
}

/**
 * Relay one inbound message synchronously to the existing Python agent
 * webhook, and return the reply text it sends back (or null to send nothing),
 * plus any chat label it wants applied. Mirrors the request/response shape of
 * POST /webhook/whatsapp in main.py, just fronted by this bridge instead of
 * Meta's Graph API. Also used (with standby: true) purely to log a message
 * to Postgres when this account isn't live yet — the agent skips reply
 * generation entirely in that case and always returns nulls.
 */
export async function relayToAgent(
  fromPhone: string,
  text: string,
  opts: RelayOptions = {}
): Promise<AgentReply> {
  const res = await fetch(config.mbWebhookUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Baileys-Secret": config.mbWebhookSecret,
    },
    body: JSON.stringify({
      from_phone: fromPhone,
      text,
      account_phone: opts.accountPhone ?? null,
      standby: opts.standby ?? false,
      human_reply: opts.humanReply ?? false,
    }),
  });
  if (!res.ok) {
    log.error({ status: res.status }, "Agent webhook returned non-OK");
    return { reply: null, label: null };
  }
  const data = (await res.json()) as { reply?: string; label?: string | null };
  return { reply: data.reply ?? null, label: data.label ?? null };
}

export interface HistoryMessage {
  from_phone: string;
  direction: "inbound" | "outbound";
  text: string;
  /** Epoch seconds from WAMessage.messageTimestamp, or null if WhatsApp didn't send one. */
  timestamp: number | null;
  wa_message_id: string | null;
}

/**
 * Bulk-logs a batch of pre-existing chat history straight to Postgres — sent
 * only once, by baileysService.ts's messaging-history.set handler, at the
 * exact moment of a fresh QR pairing (never a normal reconnect). Hits a
 * sibling path of the same agent webhook so no new config/env var is needed.
 * Unlike relayToAgent, this never calls handle_message(): nothing in a
 * history batch can generate a reply, an escalation, or a label.
 */
export async function relayHistoryToAgent(
  accountPhone: string | null,
  messages: HistoryMessage[]
): Promise<void> {
  const url = new URL(config.mbWebhookUrl);
  url.pathname = url.pathname + "/history";
  const res = await fetch(url.toString(), {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Baileys-Secret": config.mbWebhookSecret,
    },
    body: JSON.stringify({ account_phone: accountPhone, messages }),
  });
  if (!res.ok) {
    log.error({ status: res.status }, "History webhook returned non-OK");
  }
}
