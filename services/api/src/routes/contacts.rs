use crate::{
    error::AppError,
    middleware::auth::AuthUser,
    models::contact::{ContributeContactsRequest, ContributeContactsResponse},
    routes::auth::AppState,
    scoring::bayesian::normalize_caller_name,
};
use axum::{extract::State, Json};
use chrono::Utc;

pub async fn contribute_contacts(
    auth_user: AuthUser,
    State(state): State<AppState>,
    Json(payload): Json<ContributeContactsRequest>,
) -> Result<Json<ContributeContactsResponse>, AppError> {
    // Strict privacy protection: User must explicitly acknowledge consent
    if !payload.user_privacy_consent {
        return Err(AppError::Forbidden(
            "Explicit user privacy consent is required to contribute contact data".to_string(),
        ));
    }

    if payload.contacts.is_empty() {
        return Ok(Json(ContributeContactsResponse {
            processed_count: 0,
            accepted_count: 0,
            delisted_skipped_count: 0,
            consensus_promoted_count: 0,
        }));
    }

    let now = Utc::now();
    let mut accepted = 0;
    let mut delisted_skipped = 0;
    let mut consensus_promoted = 0;
    let min_consensus = state.config.min_consensus_reports;

    for contact in &payload.contacts {
        if contact.e164_number <= 0 || contact.name.trim().is_empty() {
            continue;
        }

        // 1. Check if the number is in the privacy delist registry
        let is_delisted = sqlx::query_scalar::<_, bool>(
            "SELECT EXISTS(SELECT 1 FROM delisted_numbers WHERE e164_number = $1)",
        )
        .bind(contact.e164_number)
        .fetch_one(&state.pool)
        .await?;

        if is_delisted {
            delisted_skipped += 1;
            continue;
        }

        accepted += 1;
        let normalized = normalize_caller_name(&contact.name);
        let display_name = contact.name.trim();

        // 2. Ensure number exists in master numbers table
        sqlx::query(
            r#"
            INSERT INTO numbers (e164_number, country_code, category, source_flags, updated_at)
            VALUES ($1, $2, $3, 'community_contacts', $4)
            ON CONFLICT (e164_number) DO UPDATE SET updated_at = EXCLUDED.updated_at
            "#,
        )
        .bind(contact.e164_number)
        .bind(&contact.country_code)
        .bind(if contact.is_business.unwrap_or(false) { "business" } else { "individual" })
        .bind(now)
        .execute(&state.pool)
        .await?;

        // 3. Upsert suggestion into number_name_suggestions table
        sqlx::query(
            r#"
            INSERT INTO number_name_suggestions (
                e164_number, suggested_name, normalized_name, submitter_id, votes_count, updated_at
            )
            VALUES ($1, $2, $3, $4, 1, $5)
            ON CONFLICT (e164_number, normalized_name) DO UPDATE SET
                votes_count = number_name_suggestions.votes_count + 1,
                updated_at = EXCLUDED.updated_at
            "#,
        )
        .bind(contact.e164_number)
        .bind(display_name)
        .bind(&normalized)
        .bind(auth_user.id)
        .bind(now)
        .execute(&state.pool)
        .await?;

        // 4. Evaluate community consensus for caller ID promotion
        let top_suggestion = sqlx::query_as::<_, (String, i32)>(
            r#"
            SELECT suggested_name, votes_count
            FROM number_name_suggestions
            WHERE e164_number = $1
            ORDER BY votes_count DESC
            LIMIT 1
            "#,
        )
        .bind(contact.e164_number)
        .fetch_optional(&state.pool)
        .await?;

        if let Some((top_name, votes)) = top_suggestion {
            if votes >= min_consensus {
                let total_votes = sqlx::query_scalar::<_, i64>(
                    "SELECT COALESCE(SUM(votes_count), 0) FROM number_name_suggestions WHERE e164_number = $1",
                )
                .bind(contact.e164_number)
                .fetch_one(&state.pool)
                .await? as f32;

                let confidence = if total_votes > 0.0 {
                    ((votes as f32) / total_votes).clamp(0.0, 1.0)
                } else {
                    0.5
                };

                // Promote top name to official caller ID in numbers table
                sqlx::query(
                    r#"
                    UPDATE numbers
                    SET caller_name = $1,
                        name_confidence = $2,
                        is_verified_business = CASE WHEN $3 = true THEN true ELSE is_verified_business END,
                        updated_at = $4
                    WHERE e164_number = $5 AND is_private = false
                    "#,
                )
                .bind(&top_name)
                .bind(confidence)
                .bind(contact.is_business.unwrap_or(false))
                .bind(now)
                .bind(contact.e164_number)
                .execute(&state.pool)
                .await?;

                consensus_promoted += 1;
            }
        }
    }

    Ok(Json(ContributeContactsResponse {
        processed_count: payload.contacts.len(),
        accepted_count: accepted,
        delisted_skipped_count: delisted_skipped,
        consensus_promoted_count: consensus_promoted,
    }))
}
