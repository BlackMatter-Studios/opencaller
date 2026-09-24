use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize)]
pub struct DelistRequest {
    pub e164_number: i64,
    pub reason: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct DelistResponse {
    pub e164_number: i64,
    pub status: String,
    pub message: String,
    pub delisted_at: DateTime<Utc>,
}

#[derive(Debug, Serialize)]
pub struct PrivacyStatusResponse {
    pub e164_number: i64,
    pub is_delisted: bool,
    pub is_private: bool,
}
