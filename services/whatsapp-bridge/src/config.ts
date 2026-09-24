import "dotenv/config";

function required(name: string): string {
  const v = process.env[name];
  if (!v) throw new Error(`Missing required env var: ${name}`);
  return v;
}

function normalizePhone(phone: string): string {
  return phone.replace(/[^\d]/g, "");
}

// Comma-separated E.164 numbers, e.g. "+50663314801,+50688880001". When empty,
// no restriction is applied. Used during pilots on a personal WhatsApp number
// so the bot only engages the test contact(s) and never auto-replies to the
// account owner's real personal contacts.
const allowedPhones = (process.env.BAILEYS_ALLOWED_PHONES ?? "")
  .split(",")
  .map((p) => normalizePhone(p.trim()))
  .filter(Boolean);

const bridgeAuthToken = process.env.BRIDGE_AUTH_TOKEN ?? "opencaller_baileys_secret_token";

export const config = {
  port: Number(process.env.PORT ?? 8766),
  databaseUrl: process.env.DATABASE_URL ?? "postgres://opencaller:opencaller_secure_password@postgres:5432/opencaller",
  encryptionKey: process.env.WHATSAPP_ENCRYPTION_KEY ?? "opencaller_baileys_master_encryption_key_2026",
  bridgeAuthToken,
  // Scoped-down token for the human-facing pairing link (grants only /pair,
  // /qr, /status — never /send).
  pairToken: process.env.PAIR_TOKEN || bridgeAuthToken,
  authDir: process.env.AUTH_DIR ?? "/data/auth",
  healthFile: process.env.HEALTH_FILE ?? "/tmp/healthy",
  minSendIntervalMs: Number(process.env.MIN_SEND_INTERVAL_MS ?? 1100),
  pairingTimeoutMs: Number(process.env.PAIRING_TIMEOUT_MS ?? 5 * 60 * 1000),
  minReadDelayMs: Number(process.env.MIN_READ_DELAY_MS ?? 400),
  maxReadDelayMs: Number(process.env.MAX_READ_DELAY_MS ?? 1500),
  typingMsPerChar: Number(process.env.TYPING_MS_PER_CHAR ?? 35),
  minTypingDelayMs: Number(process.env.MIN_TYPING_DELAY_MS ?? 800),
  maxTypingDelayMs: Number(process.env.MAX_TYPING_DELAY_MS ?? 6000),
  mbWebhookUrl: process.env.OPENCALLER_WEBHOOK_URL ?? process.env.MB_PY_WEBHOOK_URL ?? "http://api:8080/api/v1/auth/whatsapp/inbound",
  mbWebhookSecret: process.env.OPENCALLER_WEBHOOK_SECRET ?? process.env.MB_PY_WEBHOOK_SECRET ?? "opencaller_webhook_shared_secret",
  allowedPhones,
  standby: (process.env.BAILEYS_STANDBY ?? "false").toLowerCase() === "true",
};

export function isPhoneAllowed(phone: string): boolean {
  if (config.allowedPhones.length === 0) return true;
  return config.allowedPhones.includes(normalizePhone(phone));
}
