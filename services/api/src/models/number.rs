use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct NumberRecord {
    pub e164_number: i64,
    pub country_code: String,
    pub caller_name: Option<String>,
    pub name_confidence: f32,
    pub is_verified_business: bool,
    pub is_private: bool,
    pub spam_score: f32,
    pub report_count: i32,
    pub category: String,
    pub source_flags: String,
    pub last_reported_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LookupResponse {
    pub e164_number: i64,
    pub country_code: String,
    pub caller_name: Option<String>,
    pub name_confidence: f32,
    pub is_verified_business: bool,
    pub spam_score: f32,
    pub report_count: i32,
    pub category: String,
    pub is_spam: bool,
    pub is_private: bool,
    pub last_reported_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeltaItem {
    pub e164_number: i64,
    pub country_code: String,
    pub caller_name: Option<String>,
    pub spam_score: f32,
    pub category: String,
    pub is_verified_business: bool,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeltaResponse {
    pub items: Vec<DeltaItem>,
    pub count: usize,
    pub server_time: DateTime<Utc>,
    pub etag: String,
}
