use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize)]
pub struct ContactEntry {
    pub e164_number: i64,
    pub country_code: String,
    pub name: String,
    pub is_business: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct ContributeContactsRequest {
    pub contacts: Vec<ContactEntry>,
    /// Explicit privacy consent flag sent from client
    pub user_privacy_consent: bool,
}

#[derive(Debug, Serialize)]
pub struct ContributeContactsResponse {
    pub processed_count: usize,
    pub accepted_count: usize,
    pub delisted_skipped_count: usize,
    pub consensus_promoted_count: usize,
}
