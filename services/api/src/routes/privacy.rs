use crate::{
    error::AppError,
    models::privacy::{DelistRequest, DelistResponse, PrivacyStatusResponse},
    routes::auth::AppState,
};
use axum::{
    extract::{Path, State},
    Json,
};
use chrono::Utc;

pub async fn delist_number(
    State(state): State<AppState>,
    Json(payload): Json<DelistRequest>,
) -> Result<Json<DelistResponse>, AppError> {
    if payload.e164_number <= 0 {
        return Err(AppError::BadRequest("Invalid phone number".to_string()));
    }

    let now = Utc::now();

    // 1. Insert into delisted_numbers registry
    sqlx::query(
        r#"
        INSERT INTO delisted_numbers (e164_number, reason, delisted_at)
        VALUES ($1, $2, $3)
        ON CONFLICT (e164_number) DO UPDATE SET delisted_at = EXCLUDED.delisted_at
        "#,
    )
    .bind(payload.e164_number)
    .bind(&payload.reason)
    .bind(now)
    .execute(&state.pool)
    .await?;

    // 2. Erase caller name and purge privacy records from numbers table
    sqlx::query(
        r#"
        UPDATE numbers
        SET caller_name = NULL,
            is_private = TRUE,
            name_confidence = 0.0,
            updated_at = $1
        WHERE e164_number = $2
        "#,
    )
    .bind(now)
    .bind(payload.e164_number)
    .execute(&state.pool)
    .await?;

    // 3. Purge community suggested names to respect complete privacy
    sqlx::query(
        "DELETE FROM number_name_suggestions WHERE e164_number = $1",
    )
    .bind(payload.e164_number)
    .execute(&state.pool)
    .await?;

    tracing::info!("Number {} delisted from OpenCaller privacy index", payload.e164_number);

    Ok(Json(DelistResponse {
        e164_number: payload.e164_number,
        status: "delisted".to_string(),
        message: "Your phone number has been successfully removed from public caller ID lookups.".to_string(),
        delisted_at: now,
    }))
}

pub async fn privacy_status(
    State(state): State<AppState>,
    Path(e164_number): Path<i64>,
) -> Result<Json<PrivacyStatusResponse>, AppError> {
    let is_delisted = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(SELECT 1 FROM delisted_numbers WHERE e164_number = $1)",
    )
    .bind(e164_number)
    .fetch_one(&state.pool)
    .await?;

    let is_private = sqlx::query_scalar::<_, bool>(
        "SELECT COALESCE(is_private, false) FROM numbers WHERE e164_number = $1",
    )
    .bind(e164_number)
    .fetch_optional(&state.pool)
    .await?
    .unwrap_or(false);

    Ok(Json(PrivacyStatusResponse {
        e164_number,
        is_delisted,
        is_private: is_delisted || is_private,
    }))
}
