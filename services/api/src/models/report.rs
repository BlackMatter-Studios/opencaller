use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Report {
    pub id: Uuid,
    pub e164_number: i64,
    pub reporter_id: Option<Uuid>,
    pub category: String,
    pub comment: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Deserialize)]
pub struct CreateReportRequest {
    pub e164_number: i64,
    pub country_code: String,
    pub category: String, // 'spam', 'scam', 'telemarketing', 'delivery', 'service', 'business'
    pub caller_name: Option<String>,
    pub comment: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct ReportResponse {
    pub report_id: Uuid,
    pub e164_number: i64,
    pub new_spam_score: f32,
    pub report_count: i32,
    pub category: String,
}
