use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct FederationNode {
    pub id: Uuid,
    pub node_url: String,
    pub public_key: String,
    pub trust_weight: f32,
    pub last_synced_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FederationItem {
    pub e164_number: i64,
    pub country_code: String,
    pub caller_name: Option<String>,
    pub spam_score: f32,
    pub category: String,
    pub is_verified_business: bool,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FederationSyncPayload {
    pub node_url: String,
    pub timestamp: DateTime<Utc>,
    pub items: Vec<FederationItem>,
    /// Hex-encoded Ed25519 signature over serialized items + timestamp
    pub signature: String,
}

#[derive(Debug, Serialize)]
pub struct FederationSyncResponse {
    pub status: String,
    pub items_merged: usize,
    pub node_url: String,
}
