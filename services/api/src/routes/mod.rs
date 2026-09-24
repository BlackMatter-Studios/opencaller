pub mod auth;
pub mod contacts;
pub mod federation;
pub mod lookup;
pub mod privacy;
pub mod report;
pub mod sync;

use crate::routes::auth::AppState;
use axum::{
    routing::{get, post},
    Json, Router,
};
use serde_json::json;

pub fn create_router(state: AppState) -> Router {
    Router::new()
        // Health Check
        .route("/health", get(health_check))
        // Authentication
        .route("/v1/auth/register", post(auth::register))
        .route("/v1/auth/login", post(auth::login))
        .route("/v1/auth/me", get(auth::me))
        // Caller ID & Reputation
        .route("/v1/lookup/{number}", get(lookup::lookup_number))
        .route("/v1/report", post(report::submit_report))
        // Delta Synchronization (Pre-sorted Int64 for CallKit)
        .route("/v1/sync/delta", get(sync::get_delta))
        // Community Contacts & Consensus
        .route("/v1/contacts/contribute", post(contacts::contribute_contacts))
        // Privacy & Right to be Forgotten
        .route("/v1/privacy/delist", post(privacy::delist_number))
        .route("/v1/privacy/status/{e164_number}", get(privacy::privacy_status))
        // Federated Mesh
        .route("/v1/federation/sync", post(federation::sync_federation))
        .route("/v1/federation/nodes", get(federation::list_nodes))
        .with_state(state)
}

async fn health_check() -> Json<serde_json::Value> {
    Json(json!({
        "status": "healthy",
        "service": "opencaller-api",
        "version": env!("CARGO_PKG_VERSION"),
        "timestamp": chrono::Utc::now()
    }))
}
