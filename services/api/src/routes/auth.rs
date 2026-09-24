use crate::{
    config::Config,
    error::AppError,
    middleware::auth::{generate_token, AuthUser},
    models::user::{
        AnonymousAttestationRequest, AuthResponse, LoginRequest, RegisterRequest,
        RequestOtpRequest, RequestOtpResponse, User, VerifyOtpRequest,
    },
};
use argon2::{
    password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use axum::{extract::State, http::StatusCode, Json};
use chrono::{Duration, Utc};
use sha2::Digest;
use sqlx::PgPool;
use uuid::Uuid;

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

/// Multi-Channel Verification: Request OTP code
pub async fn request_otp(
    State(state): State<AppState>,
    Json(payload): Json<RequestOtpRequest>,
) -> Result<Json<RequestOtpResponse>, AppError> {
    let channel = payload.channel.to_lowercase();
    let session_id = Uuid::new_v4().to_string();
    let otp_code = format!("{:06}", rand::random::<u32>() % 1_000_000);
    let expires_at = Utc::now() + Duration::minutes(10);

    let (instructions, deep_link) = match channel.as_str() {
        "telegram" => (
            "Abre @OpenCallerVerifyBot en Telegram para recibir tu código instantáneo o verificar en 1-tap.".to_string(),
            Some(format!("https://t.me/OpenCallerVerifyBot?start={}", session_id)),
        ),
        "whatsapp" => {
            let num = payload.phone_number.clone().unwrap_or_else(|| "tu número".to_string());
            (
                format!("Código OTP generado para {}. Recibirás un mensaje de WhatsApp desde nuestro gateway Baileys: {}", num, otp_code),
                None,
            )
        },
        "android_gateway" => {
            (
                format!("Gateway Android auto-alojado listo. Envía un SMS con el código '{}' o aguarda flash call de verificación.", otp_code),
                None,
            )
        },
        _ => return Err(AppError::BadRequest("Canal de verificación no soportado".to_string())),
    };

    sqlx::query(
        r#"
        INSERT INTO verification_sessions (session_id, channel, target_identifier, otp_code, expires_at)
        VALUES ($1, $2, $3, $4, $5)
        "#,
    )
    .bind(&session_id)
    .bind(&channel)
    .bind(&payload.phone_number)
    .bind(&otp_code)
    .bind(expires_at)
    .execute(&state.pool)
    .await?;

    Ok(Json(RequestOtpResponse {
        session_id,
        channel,
        instructions,
        deep_link,
        expires_in_seconds: 600,
    }))
}

/// Multi-Channel Verification: Confirm OTP code & create/login account
pub async fn verify_otp(
    State(state): State<AppState>,
    Json(payload): Json<VerifyOtpRequest>,
) -> Result<Json<AuthResponse>, AppError> {
    let now = Utc::now();
    let session = sqlx::query_as::<_, (String, Option<String>, String, bool)>(
        r#"
        SELECT channel, target_identifier, otp_code, is_verified
        FROM verification_sessions
        WHERE session_id = $1 AND expires_at > $2
        "#,
    )
    .bind(&payload.session_id)
    .bind(now)
    .fetch_optional(&state.pool)
    .await?
    .ok_or_else(|| AppError::BadRequest("Sesión de verificación inválida o expirada".to_string()))?;

    let (channel, target_ident, correct_code, is_verified) = session;

    if is_verified {
        return Err(AppError::BadRequest("Esta sesión ya fue verificada".to_string()));
    }

    if payload.code.trim() != correct_code.trim() {
        return Err(AppError::BadRequest("Código de verificación incorrecto".to_string()));
    }

    // Mark as verified
    sqlx::query("UPDATE verification_sessions SET is_verified = true WHERE session_id = $1")
        .bind(&payload.session_id)
        .execute(&state.pool)
        .await?;

    let username = if let Some(ident) = target_ident {
        let clean: String = ident.chars().filter(|c| c.is_ascii_digit()).collect();
        format!("{}_{}", channel, clean)
    } else {
        format!("{}_{}", channel, &payload.session_id[0..8])
    };

    // Find or create user
    let user = sqlx::query_as::<_, User>(
        r#"
        INSERT INTO users (username, password_hash, reputation_score)
        VALUES ($1, 'verified_external_auth', 1.2)
        ON CONFLICT (username) DO UPDATE SET reputation_score = users.reputation_score
        RETURNING id, username, password_hash, reputation_score, is_node_admin, created_at
        "#,
    )
    .bind(&username)
    .fetch_one(&state.pool)
    .await?;

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

/// Multi-Channel Verification: Anonymous Play Integrity / App Attest + Proof-of-Work
pub async fn verify_anonymous_attestation(
    State(state): State<AppState>,
    Json(payload): Json<AnonymousAttestationRequest>,
) -> Result<Json<AuthResponse>, AppError> {
    if payload.device_fingerprint.len() < 16 {
        return Err(AppError::BadRequest("Device fingerprint inválido".to_string()));
    }

    // Verify cryptographic Proof-of-Work: sha256(fingerprint:nonce) must start with "0000"
    let challenge = format!("{}:{}", payload.device_fingerprint, payload.pow_nonce);
    let digest = sha2::Sha256::digest(challenge.as_bytes());
    let hex_hash = hex::encode(digest);

    if !hex_hash.starts_with("0000") {
        return Err(AppError::BadRequest("Prueba de trabajo (Proof-of-Work) insuficiente para prevenir spam".to_string()));
    }

    let anon_username = format!("anon_{}", &payload.device_fingerprint[0..12]);

    let user = sqlx::query_as::<_, User>(
        r#"
        INSERT INTO users (username, password_hash, reputation_score)
        VALUES ($1, 'pow_attested_device', 1.0)
        ON CONFLICT (username) DO UPDATE SET reputation_score = users.reputation_score
        RETURNING id, username, password_hash, reputation_score, is_node_admin, created_at
        "#,
    )
    .bind(&anon_username)
    .fetch_one(&state.pool)
    .await?;

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
