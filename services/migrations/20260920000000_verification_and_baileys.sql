-- Migration: Verification Sessions, Baileys WhatsApp Session & Hardware Attestation

-- Multi-channel verification sessions (Telegram, WhatsApp Baileys, Android Gateway)
CREATE TABLE IF NOT EXISTS verification_sessions (
    session_id VARCHAR(64) PRIMARY KEY,
    channel VARCHAR(32) NOT NULL, -- 'telegram', 'whatsapp', 'android_gateway'
    target_identifier VARCHAR(128), -- phone number or telegram user_id
    otp_code VARCHAR(16) NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_verification_sessions_expires ON verification_sessions(session_id, expires_at);

-- Single-account WhatsApp Baileys session state
CREATE TABLE IF NOT EXISTS baileys_session (
    id             SMALLINT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    status         TEXT NOT NULL DEFAULT 'disconnected',
    phone_number   TEXT,
    encrypted_creds TEXT,
    encryption_iv  TEXT,
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO baileys_session (id, status)
VALUES (1, 'disconnected')
ON CONFLICT (id) DO NOTHING;

-- Hardware Attestation Registry (Android Play Integrity & iOS App Attest)
CREATE TABLE IF NOT EXISTS attested_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id VARCHAR(128) UNIQUE NOT NULL, -- Device fingerprint or Apple App Attest key_id
    platform VARCHAR(16) NOT NULL,          -- 'android', 'ios'
    public_key TEXT,                         -- Hardware-backed public key (P-256 / Ed25519)
    sign_counter BIGINT DEFAULT 0,           -- Anti-replay monotonic counter
    attestation_status VARCHAR(32) DEFAULT 'verified',
    integrity_verdict VARCHAR(64),           -- e.g. 'MEETS_STRONG_INTEGRITY', 'APP_ATTEST_PRODUCTION'
    last_verified_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_attested_devices_platform ON attested_devices(platform, attestation_status);
