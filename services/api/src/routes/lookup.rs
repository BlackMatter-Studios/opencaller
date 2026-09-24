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
            let mut display_name = if num.is_private { None } else { num.caller_name };
            let mut confidence = num.name_confidence;

            // If caller_name is not yet set in numbers table, check suggestions for community hints
            if display_name.is_none() && !num.is_private {
                let suggestion = sqlx::query_as::<_, (String, i32)>(
                    "SELECT suggested_name, votes_count FROM number_name_suggestions WHERE e164_number = $1 ORDER BY votes_count DESC LIMIT 1"
                )
                .bind(e164)
                .fetch_optional(&state.pool)
                .await?;

                if let Some((sug_name, votes)) = suggestion {
                    display_name = Some(sug_name);
                    confidence = match votes {
                        1 => 0.35,
                        2 => 0.65,
                        _ => 0.90,
                    };
                }
            }

            Ok(Json(LookupResponse {
                e164_number: num.e164_number,
                country_code: num.country_code,
                caller_name: display_name,
                name_confidence: confidence,
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
            // Not yet in master numbers table: check if any community suggestions exist
            let suggestion = sqlx::query_as::<_, (String, i32)>(
                "SELECT suggested_name, votes_count FROM number_name_suggestions WHERE e164_number = $1 ORDER BY votes_count DESC LIMIT 1"
            )
            .bind(e164)
            .fetch_optional(&state.pool)
            .await?;

            let (display_name, confidence) = match suggestion {
                Some((name, votes)) => {
                    let conf = match votes {
                        1 => 0.35,
                        2 => 0.65,
                        _ => 0.90,
                    };
                    (Some(name), conf)
                }
                None => (None, 0.0),
            };

            Ok(Json(LookupResponse {
                e164_number: e164,
                country_code: "UNKNOWN".to_string(),
                caller_name: display_name,
                name_confidence: confidence,
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
