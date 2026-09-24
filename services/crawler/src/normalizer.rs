use regex::Regex;

#[derive(Debug, PartialEq, Clone)]
pub struct NormalizedNumber {
    pub e164: i64,
    pub country_code: String,
}

pub fn normalize_phone_number(raw: &str) -> Option<NormalizedNumber> {
    let re = Regex::new(r"[^\d]").unwrap();
    let mut digits = re.replace_all(raw, "").to_string();

    // Remove leading international trunk prefixes (e.g. 00)
    if digits.starts_with("00") {
        digits = digits[2..].to_string();
    }

    if digits.len() < 7 || digits.len() > 15 {
        return None;
    }

    let e164: i64 = digits.parse().ok()?;

    // Derive ISO country code from prefix
    let country_code = infer_country_code(&digits);

    Some(NormalizedNumber { e164, country_code })
}

fn infer_country_code(digits: &str) -> String {
    if digits.starts_with("506") {
        "CR".to_string()
    } else if digits.starts_with('1') && digits.len() == 11 {
        "US".to_string()
    } else if digits.starts_with("52") {
        "MX".to_string()
    } else if digits.starts_with("34") {
        "ES".to_string()
    } else if digits.starts_with("44") {
        "GB".to_string()
    } else if digits.starts_with("49") {
        "DE".to_string()
    } else if digits.starts_with("33") {
        "FR".to_string()
    } else if digits.starts_with("55") {
        "BR".to_string()
    } else if digits.starts_with("54") {
        "AR".to_string()
    } else if digits.starts_with("57") {
        "CO".to_string()
    } else {
        "XX".to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_normalization_variations() {
        let res1 = normalize_phone_number("+506 8888-8888").unwrap();
        assert_eq!(res1.e164, 50688888888);
        assert_eq!(res1.country_code, "CR");

        let res2 = normalize_phone_number("+1 (415) 555-0199").unwrap();
        assert_eq!(res2.e164, 14155550199);
        assert_eq!(res2.country_code, "US");

        let res3 = normalize_phone_number("0034 612 345 678").unwrap();
        assert_eq!(res3.e164, 34612345678);
        assert_eq!(res3.country_code, "ES");
    }

    #[test]
    fn test_invalid_numbers() {
        assert!(normalize_phone_number("123").is_none());
        assert!(normalize_phone_number("abc").is_none());
    }
}
