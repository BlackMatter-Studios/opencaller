use crate::{
    config::Config,
    error::AppError,
    middleware::auth::{generate_token, AuthUser},
    models::user::{AuthResponse, LoginRequest, RegisterRequest, User},
};
use argon2::{
    password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use axum::{extract::State, http::StatusCode, Json};
use sqlx::PgPool;

#[derive(Clone)]
pub struct AppState {
    pub pool: PgPool,
    pub config: Config,
}

pub async fn register(
    State(state): State<AppState>,
    Json(payload): Json<RegisterRequest>,
) -> Result<(StatusCode, Json<AuthResponse>), AppError> {
    let username = payload.username.trim();
    if username.len() < 3 || username.len() > 32 {
        return Err(AppError::BadRequest("Username must be between 3 and 32 characters".to_string()));
    }
    if payload.password.len() < 8 {
        return Err(AppError::BadRequest("Password must be at least 8 characters long".to_string()));
    }

    // Check if user exists
    let existing = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(SELECT 1 FROM users WHERE username = $1)",
    )
    .bind(username)
    .fetch_one(&state.pool)
    .await?;

    if existing {
        return Err(AppError::Conflict("Username already taken".to_string()));
    }

    // Hash password with Argon2id
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    let password_hash = argon2
        .hash_password(payload.password.as_bytes(), &salt)
        .map_err(|e| AppError::Internal(format!("Password hashing error: {}", e)))?
        .to_string();

    let user = sqlx::query_as::<_, User>(
        r#"
        INSERT INTO users (username, password_hash, reputation_score)
        VALUES ($1, $2, 1.0)
        RETURNING id, username, password_hash, reputation_score, is_node_admin, created_at
        "#,
    )
    .bind(username)
    .bind(&password_hash)
    .fetch_one(&state.pool)
    .await?;

    let token = generate_token(
        user.id,
        &user.username,
        user.is_node_admin,
        &state.config.jwt_secret,
        state.config.jwt_expiration_hours,
    )?;

    Ok((
        StatusCode::CREATED,
        Json(AuthResponse {
            token,
            user_id: user.id,
            username: user.username,
            reputation_score: user.reputation_score,
        }),
    ))
}

pub async fn login(
    State(state): State<AppState>,
    Json(payload): Json<LoginRequest>,
) -> Result<Json<AuthResponse>, AppError> {
    let username = payload.username.trim();

    let user = sqlx::query_as::<_, User>(
        "SELECT id, username, password_hash, reputation_score, is_node_admin, created_at FROM users WHERE username = $1",
    )
    .bind(username)
    .fetch_optional(&state.pool)
    .await?
    .ok_or_else(|| AppError::Unauthorized("Invalid username or password".to_string()))?;

    // Verify Argon2 password hash
    let parsed_hash = PasswordHash::new(&user.password_hash)
        .map_err(|e| AppError::Internal(format!("Corrupt password hash: {}", e)))?;
    Argon2::default()
        .verify_password(payload.password.as_bytes(), &parsed_hash)
        .map_err(|_| AppError::Unauthorized("Invalid username or password".to_string()))?;

    let token = generate_token(
        user.id,
        &user.username,
        user.is_node_admin,
        &state.config.jwt_secret,
        state.config.jwt_expiration_hours,
    )?;

    Ok(Json(AuthResponse {
        token,
        user_id: user.id,
        username: user.username,
        reputation_score: user.reputation_score,
    }))
}

pub async fn me(
    auth_user: AuthUser,
    State(state): State<AppState>,
) -> Result<Json<User>, AppError> {
    let user = sqlx::query_as::<_, User>(
        "SELECT id, username, password_hash, reputation_score, is_node_admin, created_at FROM users WHERE id = $1",
    )
    .bind(auth_user.id)
    .fetch_one(&state.pool)
    .await?;

    Ok(Json(user))
}
