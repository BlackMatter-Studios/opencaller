use crate::{
    error::AppError,
    models::number::{LookupResponse, NumberRecord},
    routes::auth::AppState,
};
use axum::{
    extract::{Path, State},
    Json,
};

pub async fn lookup_number(
    State(state): State<AppState>,
    Path(raw_number): Path<String>,
) -> Result<Json<LookupResponse>, AppError> {
    // Clean raw number string to extract purely digits
    let digits: String = raw_number.chars().filter(|c| c.is_ascii_digit()).collect();
    if digits.is_empty() {
        return Err(AppError::BadRequest("Invalid phone number format".to_string()));
    }

    let e164: i64 = digits.parse::<i64>().map_err(|_| {
        AppError::BadRequest("Phone number too long for 64-bit integer".to_string())
    })?;

    // Check if the number has exercised the Right to be Forgotten (delisted)
    let is_delisted = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(SELECT 1 FROM delisted_numbers WHERE e164_number = $1)",
    )
    .bind(e164)
    .fetch_one(&state.pool)
    .await?;

    if is_delisted {
        return Ok(Json(LookupResponse {
            e164_number: e164,
            country_code: "XX".to_string(),
            caller_name: None,
            name_confidence: 0.0,
            is_verified_business: false,
            spam_score: 0.0,
            report_count: 0,
            category: "private".to_string(),
            is_spam: false,
            is_private: true,
            last_reported_at: None,
        }));
    }

    // Query number from database
    let record = sqlx::query_as::<_, NumberRecord>(
        r#"
        SELECT e164_number, country_code, caller_name, name_confidence, is_verified_business,
               is_private, spam_score, report_count, category, source_flags, last_reported_at, updated_at
        FROM numbers
        WHERE e164_number = $1
        "#,
    )
    .bind(e164)
    .fetch_optional(&state.pool)
    .await?;

    match record {
        Some(num) => {
            let is_spam = num.spam_score >= state.config.spam_block_threshold;
            let display_name = if num.is_private { None } else { num.caller_name };

            Ok(Json(LookupResponse {
                e164_number: num.e164_number,
                country_code: num.country_code,
                caller_name: display_name,
                name_confidence: num.name_confidence,
                is_verified_business: num.is_verified_business,
                spam_score: num.spam_score,
                report_count: num.report_count,
                category: num.category,
                is_spam,
                is_private: num.is_private,
                last_reported_at: num.last_reported_at,
            }))
        }
        None => {
            // Not yet in database: return clean neutral response
            Ok(Json(LookupResponse {
                e164_number: e164,
                country_code: "UNKNOWN".to_string(),
                caller_name: None,
                name_confidence: 0.0,
                is_verified_business: false,
                spam_score: 0.0,
                report_count: 0,
                category: "unknown".to_string(),
                is_spam: false,
                is_private: false,
                last_reported_at: None,
            }))
        }
    }
}
