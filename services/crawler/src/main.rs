mod adapters;
mod normalizer;

use adapters::{git_spam_lists::GitSpamListsAdapter, open_registries::OpenRegistriesAdapter, IngestionSource};
use normalizer::normalize_phone_number;
use sqlx::postgres::PgPoolOptions;
use std::{env, sync::Arc, time::Duration};
use tokio::time::sleep;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    dotenvy::dotenv().ok();

    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info,opencaller_crawler=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    tracing::info!("Starting OpenCaller OSINT Ingestion Daemon...");

    let database_url = env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://opencaller:opencaller_secure_password@postgres:5432/opencaller".to_string());

    let interval_secs: u64 = env::var("CRAWLER_INTERVAL_SECS")
        .ok()
        .and_then(|i| i.parse().ok())
        .unwrap_or(3600);

    // Minimal connection pool: max 5 connections to respect memory limits
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .acquire_timeout(Duration::from_secs(5))
        .connect(&database_url)
        .await?;

    tracing::info!("Crawler database pool established");

    let adapters: Vec<Arc<dyn IngestionSource>> = vec![
        Arc::new(OpenRegistriesAdapter::new()),
        Arc::new(GitSpamListsAdapter::new()),
    ];

    loop {
        tracing::info!("Starting ingestion crawl cycle across {} sources...", adapters.len());
        for adapter in &adapters {
            match adapter.fetch_records().await {
                Ok(records) => {
                    let mut upserted = 0;
                    for record in records {
                        if let Some(norm) = normalize_phone_number(&record.raw_number) {
                            // Enforce privacy: Skip any number in delisted_numbers
                            let is_delisted = sqlx::query_scalar::<_, bool>(
                                "SELECT EXISTS(SELECT 1 FROM delisted_numbers WHERE e164_number = $1)",
                            )
                            .bind(norm.e164)
                            .fetch_one(&pool)
                            .await
                            .unwrap_or(false);

                            if is_delisted {
                                continue;
                            }

                            let res = sqlx::query(
                                r#"
                                INSERT INTO numbers (
                                    e164_number, country_code, caller_name, spam_score,
                                    report_count, category, source_flags, updated_at
                                )
                                VALUES ($1, $2, $3, $4, 1, $5, $6, NOW())
                                ON CONFLICT (e164_number) DO UPDATE SET
                                    spam_score = GREATEST(numbers.spam_score, EXCLUDED.spam_score),
                                    report_count = numbers.report_count + 1,
                                    caller_name = COALESCE(numbers.caller_name, EXCLUDED.caller_name),
                                    category = CASE WHEN numbers.category = 'unknown' THEN EXCLUDED.category ELSE numbers.category END,
                                    updated_at = NOW()
                                WHERE numbers.is_private = false
                                "#,
                            )
                            .bind(norm.e164)
                            .bind(&norm.country_code)
                            .bind(&record.caller_name)
                            .bind(record.spam_score)
                            .bind(&record.category)
                            .bind(&record.source)
                            .execute(&pool)
                            .await;

                            if res.is_ok() {
                                upserted += 1;
                            }
                        }
                    }
                    tracing::info!("Source '{}' processed: {} records upserted", adapter.name(), upserted);
                }
                Err(e) => {
                    tracing::error!("Error ingesting from source '{}': {:?}", adapter.name(), e);
                }
            }
        }

        tracing::info!("Ingestion cycle complete. Sleeping for {} seconds...", interval_secs);
        sleep(Duration::from_secs(interval_secs)).await;
    }
}
