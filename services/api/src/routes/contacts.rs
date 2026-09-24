use crate::{
    error::AppError,
    middleware::auth::AuthUser,
    models::contact::{ContributeContactsRequest, ContributeContactsResponse},
    routes::auth::AppState,
    scoring::{
        bayesian::normalize_caller_name,
        fuzzy::are_names_similar,
        profanity::is_profane,
    },
};
use axum::{extract::State, Json};
use chrono::Utc;
use uuid::Uuid;

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

        // 1. Multilingual profanity and abuse filter
        if is_profane(&contact.name) {
            tracing::warn!(
                "Rejected contact suggestion containing profanity/abuse for +{}",
                contact.e164_number
            );
            continue;
        }

        // 2. Check if the number is in the privacy delist registry
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

        // 3. Ensure number exists in master numbers table
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

        // 4. Fuzzy & Phonetic Clustering: Check if this name is similar to existing suggestions
        let existing_suggestions = sqlx::query_as::<_, (Uuid, String, i32)>(
            "SELECT id, suggested_name, votes_count FROM number_name_suggestions WHERE e164_number = $1",
        )
        .bind(contact.e164_number)
        .fetch_all(&state.pool)
        .await?;

        let mut matched_suggestion_id: Option<Uuid> = None;
        for (id, existing_name, _) in &existing_suggestions {
            let (similar, score) = are_names_similar(display_name, existing_name);
            if similar {
                tracing::info!(
                    "Fuzzy cluster match: '{}' matches existing '{}' (similarity: {:.2})",
                    display_name,
                    existing_name,
                    score
                );
                matched_suggestion_id = Some(*id);
                break;
            }
        }

        if let Some(sug_id) = matched_suggestion_id {
            // Cluster match found: increment vote count on existing cluster
            sqlx::query(
                "UPDATE number_name_suggestions SET votes_count = votes_count + 1, updated_at = $1 WHERE id = $2",
            )
            .bind(now)
            .bind(sug_id)
            .execute(&state.pool)
            .await?;
        } else {
            // New distinct suggestion
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
        }

        // 5. Graduated Confidence Evaluation:
        // 1 user  -> 0.35 confidence ("Podría ser...")
        // 2 users -> 0.65 confidence ("Probable...")
        // 3+ users -> 0.90 confidence (Consensus reached)
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
            let confidence: f32 = match votes {
                1 => 0.35,
                2 => 0.65,
                _ => 0.90,
            };

            // Update master caller_name and graduated confidence in numbers table
            sqlx::query(
                r#"
                UPDATE numbers
                SET caller_name = $1,
                    name_confidence = $2,
                    is_verified_business = CASE WHEN $3 = true AND $4 >= 3 THEN true ELSE is_verified_business END,
                    updated_at = $5
                WHERE e164_number = $6 AND is_private = false
                "#,
            )
            .bind(&top_name)
            .bind(confidence)
            .bind(contact.is_business.unwrap_or(false))
            .bind(votes)
            .bind(now)
            .bind(contact.e164_number)
            .execute(&state.pool)
            .await?;

            if votes >= min_consensus {
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
