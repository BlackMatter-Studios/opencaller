import { getDb } from "./db.js";
import { encryptCredentials, decryptCredentials } from "./encryption.js";
import { config } from "./config.js";
import { createLogger } from "./logger.js";

const log = createLogger("session-store");

// "connecting" is the brief window between a successful QR scan and the
// connection reopening with now-registered credentials — WhatsApp forces a
// disconnect right after a scan (DisconnectReason.restartRequired) as an
// expected step of pairing, not a failure; see baileysService.ts.
export type ConnectionStatus = "disconnected" | "pairing" | "connecting" | "connected";

/**
 * Single-row table (id = 1), pre-seeded by the 001_schema.sql migration.
 * Status updates and credential updates are two separate, narrowly-targeted
 * UPDATE statements so a status change never clobbers previously-saved creds.
 */

export async function loadCredentials(): Promise<string | null> {
  const sql = getDb();
  const rows = await sql<{ encrypted_creds: string | null; encryption_iv: string | null }[]>`
    SELECT encrypted_creds, encryption_iv FROM baileys_session WHERE id = 1
  `;
  const row = rows[0];
  if (!row || !row.encrypted_creds || !row.encryption_iv) return null;
  try {
    return decryptCredentials(row.encrypted_creds, row.encryption_iv, config.encryptionKey);
  } catch (err) {
    log.error({ err }, "Failed to decrypt stored credentials");
    return null;
  }
}

export async function saveCredentials(plaintextJson: string): Promise<void> {
  const sql = getDb();
  const { ciphertext, iv } = encryptCredentials(plaintextJson, config.encryptionKey);
  await sql`
    UPDATE baileys_session
    SET encrypted_creds = ${ciphertext}, encryption_iv = ${iv}, updated_at = now()
    WHERE id = 1
  `;
}

export async function clearCredentials(): Promise<void> {
  const sql = getDb();
  await sql`
    UPDATE baileys_session
    SET encrypted_creds = NULL, encryption_iv = NULL, updated_at = now()
    WHERE id = 1
  `;
}

export async function setStatus(status: ConnectionStatus, phone?: string): Promise<void> {
  const sql = getDb();
  await sql`
    UPDATE baileys_session
    SET status = ${status},
        phone_number = COALESCE(${phone ?? null}, phone_number),
        updated_at = now()
    WHERE id = 1
  `;
}

export async function getStatus(): Promise<{ status: ConnectionStatus; phone_number: string | null } | null> {
  const sql = getDb();
  const rows = await sql<{ status: ConnectionStatus; phone_number: string | null }[]>`
    SELECT status, phone_number FROM baileys_session WHERE id = 1
  `;
  return rows[0] ?? null;
}
