pub mod git_spam_lists;
pub mod open_registries;

use async_trait::async_trait;

#[derive(Debug, Clone)]
pub struct IngestionRecord {
    pub raw_number: String,
    pub caller_name: Option<String>,
    pub category: String,
    pub spam_score: f32,
    pub source: String,
}

#[async_trait]
pub trait IngestionSource: Send + Sync {
    fn name(&self) -> &str;
    async fn fetch_records(&self) -> Result<Vec<IngestionRecord>, Box<dyn std::error::Error + Send + Sync>>;
}
