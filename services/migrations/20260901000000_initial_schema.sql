-- OpenCaller Initial PostgreSQL Schema
-- Tuned for high-concurrency and strict E.164 numerical storage

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- User Accounts & Reputation
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(64) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    reputation_score REAL DEFAULT 1.0,
    is_node_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Master Numbers Registry
CREATE TABLE IF NOT EXISTS numbers (
    e164_number BIGINT PRIMARY KEY, -- Strictly numeric E.164 (e.g. 50688888888, no '+' sign)
    country_code VARCHAR(8) NOT NULL,
    caller_name VARCHAR(128),
    name_confidence REAL DEFAULT 0.0, -- Confidence score (0.0 to 1.0) derived from consensus
    is_verified_business BOOLEAN DEFAULT FALSE,
    is_private BOOLEAN DEFAULT FALSE, -- Flagged as private by owner
    spam_score REAL DEFAULT 0.00, -- Normalized 0.00 (clean) to 1.00 (severe scam/spam)
    report_count INT DEFAULT 0,
    category VARCHAR(32) DEFAULT 'unknown', -- 'spam', 'scam', 'telemarketing', 'delivery', 'service', 'business', 'individual'
    source_flags VARCHAR(64) DEFAULT 'community', -- 'community', 'crawler', 'ftc_feed', 'verified_org'
    last_reported_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for ultra-fast filtering & ascending delta sync
CREATE INDEX IF NOT EXISTS idx_numbers_country_spam ON numbers(country_code, spam_score);
CREATE INDEX IF NOT EXISTS idx_numbers_updated_at ON numbers(updated_at);
CREATE INDEX IF NOT EXISTS idx_numbers_country_updated ON numbers(country_code, updated_at);

-- Community Name Suggestions for Consensus Resolution
CREATE TABLE IF NOT EXISTS number_name_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    e164_number BIGINT NOT NULL REFERENCES numbers(e164_number) ON DELETE CASCADE,
    suggested_name VARCHAR(128) NOT NULL,
    normalized_name VARCHAR(128) NOT NULL,
    submitter_id UUID REFERENCES users(id) ON DELETE SET NULL,
    votes_count INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_number_normalized_name UNIQUE (e164_number, normalized_name)
);

CREATE INDEX IF NOT EXISTS idx_name_suggestions_number ON number_name_suggestions(e164_number, votes_count DESC);

-- Community Spam & Caller Reports
CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    e164_number BIGINT NOT NULL REFERENCES numbers(e164_number) ON DELETE CASCADE,
    reporter_id UUID REFERENCES users(id) ON DELETE SET NULL,
    category VARCHAR(32) NOT NULL,
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reports_number ON reports(e164_number);
CREATE INDEX IF NOT EXISTS idx_reports_reporter ON reports(reporter_id);

-- Privacy Delist Registry ("Right to be Forgotten" / Opt-Out)
CREATE TABLE IF NOT EXISTS delisted_numbers (
    e164_number BIGINT PRIMARY KEY,
    reason TEXT,
    delisted_at TIMESTAMPTZ DEFAULT NOW()
);

-- Federated Mesh Nodes
CREATE TABLE IF NOT EXISTS federation_nodes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    node_url TEXT UNIQUE NOT NULL,
    public_key TEXT NOT NULL,
    trust_weight REAL DEFAULT 0.5,
    last_synced_at TIMESTAMPTZ
);
