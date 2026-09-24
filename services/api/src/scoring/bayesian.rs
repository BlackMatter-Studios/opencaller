/// Calculate Bayesian spam score based on previous score, report category, and reporter trust
pub fn compute_updated_spam_score(
    current_score: f32,
    current_count: i32,
    category: &str,
    reporter_trust: f32,
) -> f32 {
    let category_impact = match category.to_lowercase().as_str() {
        "scam" | "fraud" | "phishing" => 0.35,
        "spam" | "telemarketing" | "robocall" => 0.20,
        "harassment" => 0.30,
        "delivery" | "courier" | "service" => -0.15,
        "business" | "verified" => -0.25,
        _ => 0.10,
    };

    let weight = (reporter_trust.clamp(0.1, 2.0) * category_impact) / (1.0 + (current_count as f32 * 0.1));
    let new_score = current_score + weight;
    new_score.clamp(0.00, 1.00)
}

/// Normalizes a human-entered name for clustering and consensus calculation
pub fn normalize_caller_name(raw: &str) -> String {
    raw.trim()
        .to_lowercase()
        .split_whitespace()
        .collect::<Vec<&str>>()
        .join(" ")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_spam_score_escalation() {
        let mut score = 0.0;
        let mut count = 0;

        // User reports scam
        score = compute_updated_spam_score(score, count, "scam", 1.0);
        count += 1;
        assert!(score >= 0.30);

        // Another user reports scam
        score = compute_updated_spam_score(score, count, "scam", 1.0);
        count += 1;
        assert!(score >= 0.55);

        // Third report pushes it high
        score = compute_updated_spam_score(score, count, "scam", 1.0);
        assert!(score >= 0.70);
    }

    #[test]
    fn test_legitimate_service_reduces_spam() {
        let score = compute_updated_spam_score(0.40, 1, "delivery", 1.0);
        assert!(score < 0.40);
    }

    #[test]
    fn test_normalize_name() {
        assert_eq!(normalize_caller_name("  Amazon   Delivery  "), "amazon delivery");
    }
}
