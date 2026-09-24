use sqlx::postgres::{PgPool, PgPoolOptions};
use std::time::Duration;

pub async fn create_pool(database_url: &str) -> Result<PgPool, sqlx::Error> {
    let pool = PgPoolOptions::new()
        .max_connections(20)
        .min_connections(2)
        .acquire_timeout(Duration::from_secs(5))
        .idle_timeout(Duration::from_secs(600))
        .max_lifetime(Duration::from_secs(1800))
        .connect(database_url)
        .await?;

    // Self-healing schema additions (run as separate queries)
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS verification_sessions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            session_id VARCHAR(64) UNIQUE NOT NULL,
            channel VARCHAR(32) NOT NULL,
            target_identifier VARCHAR(64),
            otp_code VARCHAR(16) NOT NULL,
            is_verified BOOLEAN DEFAULT FALSE,
            expires_at TIMESTAMPTZ NOT NULL,
            created_at TIMESTAMPTZ DEFAULT NOW()
        )
        "#
    )
    .execute(&pool)
    .await?;

    sqlx::query(
        "CREATE INDEX IF NOT EXISTS idx_verif_session_id ON verification_sessions(session_id)"
    )
    .execute(&pool)
    .await?;

    Ok(pool)
}
