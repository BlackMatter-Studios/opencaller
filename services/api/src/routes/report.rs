use crate::{
    error::AppError,
    models::{
        number::NumberRecord,
        report::{CreateReportRequest, ReportResponse},
    },
    routes::auth::AppState,
    scoring::bayesian::compute_updated_spam_score,
};
use axum::{
    extract::State,
    http::{header::AUTHORIZATION, HeaderMap},
    Json,
};
use chrono::Utc;
use uuid::Uuid;

pub async fn submit_report(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(payload): Json<CreateReportRequest>,
) -> Result<Json<ReportResponse>, AppError> {
    if payload.e164_number <= 0 {
        return Err(AppError::BadRequest("Invalid E.164 number".to_string()));
    }

    // Determine reporter ID and trust weight if auth token is present
    let (reporter_id, reporter_trust) = if let Some(auth_val) = headers.get(AUTHORIZATION) {
        if let Ok(auth_str) = auth_val.to_str() {
            if auth_str.starts_with("Bearer ") {
                let token = &auth_str["Bearer ".len()..];
                if let Ok(claims) = crate::middleware::auth::verify_token(token, &state.config.jwt_secret) {
                    let trust = sqlx::query_scalar::<_, f32>(
                        "SELECT reputation_score FROM users WHERE id = $1",
                    )
                    .bind(claims.sub)
                    .fetch_optional(&state.pool)
                    .await?
                    .unwrap_or(1.0);
                    (Some(claims.sub), trust)
                } else {
                    (None, 0.8)
                }
            } else {
                (None, 0.8)
            }
        } else {
            (None, 0.8)
        }
    } else {
        (None, 0.8)
    };

    let now = Utc::now();

    // Query existing number record or initialize defaults
    let existing = sqlx::query_as::<_, NumberRecord>(
        "SELECT e164_number, country_code, caller_name, name_confidence, is_verified_business, is_private, spam_score, report_count, category, source_flags, last_reported_at, updated_at FROM numbers WHERE e164_number = $1",
    )
    .bind(payload.e164_number)
    .fetch_optional(&state.pool)
    .await?;

    let (current_score, current_count, current_name) = match &existing {
        Some(num) => (num.spam_score, num.report_count, num.caller_name.clone()),
        None => (0.0, 0, None),
    };

    let new_spam_score = compute_updated_spam_score(
        current_score,
        current_count,
        &payload.category,
        reporter_trust,
    );
    let new_report_count = current_count + 1;

    let caller_name = payload.caller_name.or(current_name);

    // Upsert into master numbers table
    sqlx::query(
        r#"
        INSERT INTO numbers (
            e164_number, country_code, caller_name, spam_score, report_count,
            category, source_flags, last_reported_at, updated_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, 'community', $7, $7)
        ON CONFLICT (e164_number) DO UPDATE SET
            spam_score = EXCLUDED.spam_score,
            report_count = EXCLUDED.report_count,
            category = EXCLUDED.category,
            caller_name = COALESCE(numbers.caller_name, EXCLUDED.caller_name),
            last_reported_at = EXCLUDED.last_reported_at,
            updated_at = EXCLUDED.updated_at
        "#,
    )
    .bind(payload.e164_number)
    .bind(&payload.country_code)
    .bind(&caller_name)
    .bind(new_spam_score)
    .bind(new_report_count)
    .bind(&payload.category)
    .bind(now)
    .execute(&state.pool)
    .await?;

    // Record the specific report entry
    let report_id = Uuid::new_v4();
    sqlx::query(
        r#"
        INSERT INTO reports (id, e164_number, reporter_id, category, comment, created_at)
        VALUES ($1, $2, $3, $4, $5, $6)
        "#,
    )
    .bind(report_id)
    .bind(payload.e164_number)
    .bind(reporter_id)
    .bind(&payload.category)
    .bind(&payload.comment)
    .bind(now)
    .execute(&state.pool)
    .await?;

    Ok(Json(ReportResponse {
        report_id,
        e164_number: payload.e164_number,
        new_spam_score,
        report_count: new_report_count,
        category: payload.category,
    }))
}
