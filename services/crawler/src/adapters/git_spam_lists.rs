use super::{IngestionRecord, IngestionSource};
use async_trait::async_trait;

pub struct GitSpamListsAdapter;

impl GitSpamListsAdapter {
    pub fn new() -> Self {
        Self
    }
}

#[async_trait]
impl IngestionSource for GitSpamListsAdapter {
    fn name(&self) -> &str {
        "git_spam_lists"
    }

    async fn fetch_records(&self) -> Result<Vec<IngestionRecord>, Box<dyn std::error::Error + Send + Sync>> {
        // Community open-source spam collection
        let records = vec![
            IngestionRecord {
                raw_number: "+14155552671".to_string(),
                caller_name: Some("Auto Warranty Robocall".to_string()),
                category: "telemarketing".to_string(),
                spam_score: 0.88,
                source: "git_spam_lists".to_string(),
            },
            IngestionRecord {
                raw_number: "+442079460912".to_string(),
                caller_name: Some("Crypto Investment Boiler Room".to_string()),
                category: "scam".to_string(),
                spam_score: 0.96,
                source: "git_spam_lists".to_string(),
            },
            IngestionRecord {
                raw_number: "+50688889999".to_string(),
                caller_name: Some("Prison Cell Extortion Ring".to_string()),
                category: "scam".to_string(),
                spam_score: 0.99,
                source: "git_spam_lists".to_string(),
            },
        ];

        Ok(records)
    }
}
