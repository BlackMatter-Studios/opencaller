use std::env;

#[derive(Clone, Debug)]
pub struct Config {
    pub host: String,
    pub port: u16,
    pub database_url: String,
    pub jwt_secret: String,
    pub jwt_expiration_hours: i64,
    pub min_consensus_reports: i32,
    pub spam_block_threshold: f32,
    pub node_domain: String,
}

impl Config {
    pub fn from_env() -> Self {
        dotenvy::dotenv().ok();

        Self {
            host: env::var("HOST").unwrap_or_else(|_| "0.0.0.0".to_string()),
            port: env::var("PORT")
                .ok()
                .and_then(|p| p.parse().ok())
                .unwrap_or(8080),
            database_url: env::var("DATABASE_URL")
                .unwrap_or_else(|_| "postgres://opencaller:opencaller_secure_password@postgres:5432/opencaller".to_string()),
            jwt_secret: env::var("JWT_SECRET")
                .unwrap_or_else(|_| "default_insecure_jwt_secret_must_change_in_production".to_string()),
            jwt_expiration_hours: env::var("JWT_EXPIRATION_HOURS")
                .ok()
                .and_then(|h| h.parse().ok())
                .unwrap_or(720),
            min_consensus_reports: env::var("MIN_CONSENSUS_REPORTS")
                .ok()
                .and_then(|r| r.parse().ok())
                .unwrap_or(3),
            spam_block_threshold: env::var("SPAM_BLOCK_THRESHOLD")
                .ok()
                .and_then(|t| t.parse().ok())
                .unwrap_or(0.80),
            node_domain: env::var("NODE_DOMAIN")
                .unwrap_or_else(|_| "opencaller.blackmatter.cc".to_string()),
        }
    }
}
