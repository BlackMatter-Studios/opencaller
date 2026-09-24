use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct User {
    pub id: Uuid,
    pub username: String,
    pub password_hash: String,
    pub reputation_score: f32,
    pub is_node_admin: bool,
    pub created_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    pub username: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub username: String,
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub token: String,
    pub user_id: Uuid,
    pub username: String,
    pub reputation_score: f32,
}

#[derive(Debug, Deserialize)]
pub struct RequestOtpRequest {
    pub channel: String, // "telegram", "whatsapp", "android_gateway"
    pub phone_number: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct RequestOtpResponse {
    pub session_id: String,
    pub channel: String,
    pub instructions: String,
    pub deep_link: Option<String>,
    pub expires_in_seconds: u32,
}

#[derive(Debug, Deserialize)]
pub struct VerifyOtpRequest {
    pub session_id: String,
    pub code: String,
}

#[derive(Debug, Deserialize)]
pub struct AnonymousAttestationRequest {
    pub device_fingerprint: String,
    pub pow_nonce: u64,
    pub client_platform: String, // "android" or "ios"
}

#[derive(Debug, Deserialize)]
pub struct TelegramConfirmRequest {
    pub session_id: Option<String>,
    pub telegram_user_id: i64,
    pub telegram_username: Option<String>,
    pub phone_number: String,
    pub first_name: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct HardwareAttestRequest {
    pub platform: String, // "android" or "ios"
    pub device_id: String, // Android package / iOS Key ID
    pub attestation_payload: String, // Play Integrity token or App Attest CBOR/Receipt
    pub client_nonce: String,
}

