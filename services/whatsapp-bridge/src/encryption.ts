import crypto from "node:crypto";

const ALGO = "aes-256-gcm";
const IV_LENGTH = 12;

function deriveKey(passphrase: string): Buffer {
  return crypto.createHash("sha256").update(passphrase).digest();
}

export function encryptCredentials(plaintext: string, passphrase: string): { ciphertext: string; iv: string } {
  const key = deriveKey(passphrase);
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ALGO, key, iv);
  const encrypted = Buffer.concat([cipher.update(plaintext, "utf8"), cipher.final()]);
  const authTag = cipher.getAuthTag();
  return {
    ciphertext: Buffer.concat([encrypted, authTag]).toString("base64"),
    iv: iv.toString("base64"),
  };
}

export function decryptCredentials(ciphertext: string, iv: string, passphrase: string): string {
  const key = deriveKey(passphrase);
  const ivBuf = Buffer.from(iv, "base64");
  const data = Buffer.from(ciphertext, "base64");
  const authTag = data.subarray(data.length - 16);
  const encrypted = data.subarray(0, data.length - 16);
  const decipher = crypto.createDecipheriv(ALGO, key, ivBuf);
  decipher.setAuthTag(authTag);
  const decrypted = Buffer.concat([decipher.update(encrypted), decipher.final()]);
  return decrypted.toString("utf8");
}
