use crate::{
    error::AppError,
    models::federation::{FederationNode, FederationSyncPayload, FederationSyncResponse},
    routes::auth::AppState,
};
use axum::{extract::State, Json};
use chrono::Utc;

pub async fn sync_federation(
    State(state): State<AppState>,
    Json(payload): Json<FederationSyncPayload>,
) -> Result<Json<FederationSyncResponse>, AppError> {
    // 1. Verify if peer node is registered in federation_nodes
    let node = sqlx::query_as::<_, FederationNode>(
        "SELECT id, node_url, public_key, trust_weight, last_synced_at FROM federation_nodes WHERE node_url = $1",
    )
    .bind(&payload.node_url)
    .fetch_optional(&state.pool)
    .await?
    .ok_or_else(|| AppError::Forbidden("Untrusted or unregistered federation node".to_string()))?;

    let now = Utc::now();
    let mut merged = 0;

    for item in payload.items {
        // Skip delisted numbers to preserve privacy across mesh
        let is_delisted = sqlx::query_scalar::<_, bool>(
            "SELECT EXISTS(SELECT 1 FROM delisted_numbers WHERE e164_number = $1)",
        )
        .bind(item.e164_number)
        .fetch_one(&state.pool)
        .await?;

        if is_delisted {
            continue;
        }

        // Merge record using node's trust weight
        sqlx::query(
            r#"
            INSERT INTO numbers (
                e164_number, country_code, caller_name, spam_score, report_count,
                category, source_flags, updated_at
            )
            VALUES ($1, $2, $3, $4, 1, $5, 'federation', $6)
            ON CONFLICT (e164_number) DO UPDATE SET
                spam_score = (numbers.spam_score + (EXCLUDED.spam_score * $7)) / (1.0 + $7),
                category = CASE WHEN numbers.category = 'unknown' THEN EXCLUDED.category ELSE numbers.category END,
                caller_name = COALESCE(numbers.caller_name, EXCLUDED.caller_name),
                updated_at = EXCLUDED.updated_at
            WHERE numbers.is_private = false
            "#,
        )
        .bind(item.e164_number)
        .bind(&item.country_code)
        .bind(&item.caller_name)
        .bind(item.spam_score)
        .bind(&item.category)
        .bind(now)
        .bind(node.trust_weight)
        .execute(&state.pool)
        .await?;

        merged += 1;
    }

    // Update last synced time for this peer node
    sqlx::query(
        "UPDATE federation_nodes SET last_synced_at = $1 WHERE id = $2",
    )
    .bind(now)
    .bind(node.id)
    .execute(&state.pool)
    .await?;

    Ok(Json(FederationSyncResponse {
        status: "success".to_string(),
        items_merged: merged,
        node_url: payload.node_url,
    }))
}

pub async fn list_nodes(
    State(state): State<AppState>,
) -> Result<Json<Vec<FederationNode>>, AppError> {
    let nodes = sqlx::query_as::<_, FederationNode>(
        "SELECT id, node_url, public_key, trust_weight, last_synced_at FROM federation_nodes ORDER BY trust_weight DESC",
    )
    .fetch_all(&state.pool)
    .await?;

    Ok(Json(nodes))
}
