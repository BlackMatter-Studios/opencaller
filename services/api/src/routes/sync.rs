use crate::{
    error::AppError,
    middleware::etag::{generate_etag, matches_if_none_match},
    models::number::{DeltaItem, DeltaResponse},
    routes::auth::AppState,
};
use axum::{
    extract::{Query, State},
    http::{
        header::{CACHE_CONTROL, ETAG, IF_NONE_MATCH},
        HeaderMap, HeaderValue, StatusCode,
    },
    response::{IntoResponse, Response},
    Json,
};
use chrono::{DateTime, Utc};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct SyncParams {
    pub country: String,
    pub since: Option<DateTime<Utc>>,
    pub limit: Option<i64>,
}

pub async fn get_delta(
    State(state): State<AppState>,
    headers: HeaderMap,
    Query(params): Query<SyncParams>,
) -> Result<Response, AppError> {
    let country = params.country.to_uppercase();
    let since = params.since.unwrap_or_else(|| {
        DateTime::from_timestamp(0, 0).unwrap_or_default()
    });
    let limit = params.limit.unwrap_or(5000).clamp(1, 20000);

    // CRITICAL: Strictly sorted in ASCENDING order by e164_number for iOS CXCallDirectoryProvider
    let rows = sqlx::query_as::<_, (i64, String, Option<String>, f32, String, bool, bool, DateTime<Utc>)>(
        r#"
        SELECT e164_number, country_code, caller_name, spam_score, category,
               is_verified_business, is_private, updated_at
        FROM numbers
        WHERE country_code = $1 AND updated_at > $2
        ORDER BY e164_number ASC
        LIMIT $3
        "#,
    )
    .bind(&country)
    .bind(since)
    .bind(limit)
    .fetch_all(&state.pool)
    .await?;

    let items: Vec<DeltaItem> = rows
        .into_iter()
        .map(|(num, ccode, name, score, cat, verified, is_priv, updated)| {
            let caller_name = if is_priv { None } else { name };
            DeltaItem {
                e164_number: num,
                country_code: ccode,
                caller_name,
                spam_score: score,
                category: cat,
                is_verified_business: verified,
                updated_at: updated,
            }
        })
        .collect();

    let server_time = Utc::now();
    let count = items.len();

    // Serialize payload to compute ETag
    let raw_json = serde_json::to_vec(&items).unwrap_or_default();
    let etag = generate_etag(&raw_json);

    // Check If-None-Match conditional request
    let client_etag = headers.get(IF_NONE_MATCH).and_then(|h| h.to_str().ok());
    if matches_if_none_match(client_etag, &etag) {
        let mut response = StatusCode::NOT_MODIFIED.into_response();
        response.headers_mut().insert(ETAG, HeaderValue::from_str(&etag).unwrap());
        response.headers_mut().insert(
            CACHE_CONTROL,
            HeaderValue::from_static("public, max-age=60, stale-while-revalidate=300"),
        );
        return Ok(response);
    }

    let response_body = DeltaResponse {
        items,
        count,
        server_time,
        etag: etag.clone(),
    };

    let mut response = (StatusCode::OK, Json(response_body)).into_response();
    response.headers_mut().insert(ETAG, HeaderValue::from_str(&etag).unwrap());
    response.headers_mut().insert(
        CACHE_CONTROL,
        HeaderValue::from_static("public, max-age=60, stale-while-revalidate=300"),
    );

    Ok(response)
}
