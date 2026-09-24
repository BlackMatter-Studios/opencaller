-- Single-account WhatsApp Baileys session state for Monkey Box.
-- Deliberately one row (id = 1): this bridge talks to exactly one WhatsApp number.
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
