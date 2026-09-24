use sha2::{Digest, Sha256};

pub fn generate_etag(data: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(data);
    let hash = hasher.finalize();
    format!("\"{}\"", hex::encode(&hash[..16]))
}

pub fn matches_if_none_match(if_none_match: Option<&str>, etag: &str) -> bool {
    match if_none_match {
        Some(client_etag) => {
            let client_clean = client_etag.trim().trim_start_matches("W/");
            let server_clean = etag.trim().trim_start_matches("W/");
            client_clean == server_clean || client_clean == "*"
        }
        None => false,
    }
}
