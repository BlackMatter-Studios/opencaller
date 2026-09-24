/// Fuzzy and Phonetic Name Similarity Engine
/// Handles tokenization, business stop-word stripping, Jaro-Winkler distance,
/// and Levenshtein metrics to cluster similar crowdsourced caller names
/// (e.g., "Hamburguesas Dooguies" vs "Restaurante Dugis")

const BUSINESS_STOP_WORDS: &[&str] = &[
    // Business types
    "restaurante", "restaurant", "hamburguesas", "burgers", "burger", "pizzeria",
    "pizza", "taqueria", "tacos", "cafeteria", "cafe", "coffee", "tienda", "shop",
    "supermercado", "super", "farmacia", "pharmacy", "taller", "mecanica", "clinica",
    "hospital", "banco", "bank", "hotel", "hostel", "bar", "pub", "comida", "food",
    "servicios", "service", "express", "delivery", "distribuidora",
    // Titles & Honorifics
    "lic", "lic.", "dr", "dr.", "dra", "dra.", "ing", "ing.", "abogado", "prof", "don", "doña",
    // Corporate suffixes
    "sa", "s.a.", "srl", "s.r.l.", "ltda", "limitada", "inc", "corp", "llc", "co", "cia",
    // Articles & prepositions
    "de", "del", "el", "la", "los", "las", "y", "e", "the", "and", "of",
];

/// Extracts core semantic tokens by stripping common business category prefixes and suffixes
pub fn extract_core_tokens(name: &str) -> Vec<String> {
    let lower = name.trim().to_lowercase();
    let cleaned: String = lower
        .chars()
        .map(|c| if c.is_alphanumeric() || c.is_whitespace() { c } else { ' ' })
        .collect();

    let tokens: Vec<String> = cleaned
        .split_whitespace()
        .filter(|t| !BUSINESS_STOP_WORDS.contains(&t) && t.len() >= 2)
        .map(|s| s.to_string())
        .collect();

    if tokens.is_empty() {
        // If all words were stop words, fall back to non-stop words of any length or raw tokens
        cleaned.split_whitespace().map(|s| s.to_string()).collect()
    } else {
        tokens
    }
}

/// Computes Levenshtein edit distance between two strings
pub fn levenshtein_distance(s1: &str, s2: &str) -> usize {
    let len1 = s1.chars().count();
    let len2 = s2.chars().count();

    if len1 == 0 { return len2; }
    if len2 == 0 { return len1; }

    let chars1: Vec<char> = s1.chars().collect();
    let chars2: Vec<char> = s2.chars().collect();

    let mut prev_row: Vec<usize> = (0..=len2).collect();
    let mut curr_row: Vec<usize> = vec![0; len2 + 1];

    for i in 0..len1 {
        curr_row[0] = i + 1;
        for j in 0..len2 {
            let cost = if chars1[i] == chars2[j] { 0 } else { 1 };
            curr_row[j + 1] = (prev_row[j + 1] + 1)
                .min(curr_row[j] + 1)
                .min(prev_row[j] + cost);
        }
        prev_row.copy_from_slice(&curr_row);
    }

    prev_row[len2]
}

/// Computes Jaro similarity (0.0 to 1.0)
pub fn jaro_similarity(s1: &str, s2: &str) -> f64 {
    let a: Vec<char> = s1.chars().collect();
    let b: Vec<char> = s2.chars().collect();

    let len_a = a.len();
    let len_b = b.len();

    if len_a == 0 && len_b == 0 { return 1.0; }
    if len_a == 0 || len_b == 0 { return 0.0; }

    let match_distance = (len_a.max(len_b) / 2).saturating_sub(1);

    let mut a_matches = vec![false; len_a];
    let mut b_matches = vec![false; len_b];

    let mut matches = 0;
    for i in 0..len_a {
        let start = i.saturating_sub(match_distance);
        let end = (i + match_distance + 1).min(len_b);

        for j in start..end {
            if b_matches[j] || a[i] != b[j] { continue; }
            a_matches[i] = true;
            b_matches[j] = true;
            matches += 1;
            break;
        }
    }

    if matches == 0 { return 0.0; }

    let mut transpositions = 0;
    let mut k = 0;
    for i in 0..len_a {
        if !a_matches[i] { continue; }
        while !b_matches[k] { k += 1; }
        if a[i] != b[k] {
            transpositions += 1;
        }
        k += 1;
    }

    let m = matches as f64;
    let t = (transpositions / 2) as f64;
    ((m / len_a as f64) + (m / len_b as f64) + ((m - t) / m)) / 3.0
}

/// Computes Jaro-Winkler similarity (0.0 to 1.0) with prefix bonus
pub fn jaro_winkler_similarity(s1: &str, s2: &str) -> f64 {
    let jaro = jaro_similarity(s1, s2);
    if jaro < 0.7 {
        return jaro;
    }

    let a: Vec<char> = s1.chars().collect();
    let b: Vec<char> = s2.chars().collect();
    let max_prefix = 4.min(a.len()).min(b.len());

    let mut prefix_len = 0;
    for i in 0..max_prefix {
        if a[i] == b[i] {
            prefix_len += 1;
        } else {
            break;
        }
    }

    let p = 0.1; // Scaling factor
    jaro + (prefix_len as f64 * p * (1.0 - jaro))
}

/// Determines whether two caller names refer to the same entity
/// Returns (is_similar, confidence_score)
pub fn are_names_similar(name_a: &str, name_b: &str) -> (bool, f64) {
    let tokens_a = extract_core_tokens(name_a);
    let tokens_b = extract_core_tokens(name_b);

    if tokens_a.is_empty() || tokens_b.is_empty() {
        return (false, 0.0);
    }

    let core_a = tokens_a.join(" ");
    let core_b = tokens_b.join(" ");

    // 1. Direct match after stop-word removal
    if core_a == core_b {
        return (true, 1.0);
    }

    // 2. Cross-token Jaro-Winkler similarity
    let jw = jaro_winkler_similarity(&core_a, &core_b);
    if jw >= 0.75 {
        return (true, jw);
    }

    // 3. Substring containment if token length is substantial (>= 4 chars)
    if (core_a.len() >= 4 && core_b.contains(&core_a)) || (core_b.len() >= 4 && core_a.contains(&core_b)) {
        return (true, 0.85);
    }

    // 4. Token-by-token comparison (best pairwise match)
    for ta in &tokens_a {
        for tb in &tokens_b {
            let pair_jw = jaro_winkler_similarity(ta, tb);
            let dist = levenshtein_distance(ta, tb);
            if pair_jw >= 0.80 || (dist <= 2 && ta.len().min(tb.len()) >= 4) {
                return (true, pair_jw.max(0.75));
            }
        }
    }

    (false, jw)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_user_example_dooguies_vs_dugis() {
        // "Hamburguesas Dooguies" vs "Restaurante Dugis"
        let (similar, score) = are_names_similar("Hamburguesas Dooguies", "Restaurante Dugis");
        assert!(similar, "Expected similar but got false with score {}", score);
        assert!(score >= 0.70, "Score should be >= 0.70, got {}", score);
    }

    #[test]
    fn test_inverted_tokens() {
        // "Pizzeria Mario" vs "Mario Pizzeria"
        let (similar, score) = are_names_similar("Pizzeria Mario", "Mario Pizzeria");
        assert!(similar);
        assert!(score >= 0.80);
    }

    #[test]
    fn test_different_entities_no_match() {
        // "Uber Eats" vs "Didi Food"
        let (similar, _) = are_names_similar("Uber Eats", "Didi Food");
        assert!(!similar);
    }

    #[test]
    fn test_sub_brand() {
        // "Banco Nacional Sucursal Escazu" vs "Banco Nacional"
        let (similar, _) = are_names_similar("Banco Nacional Sucursal Escazu", "Banco Nacional");
        assert!(similar);
    }
}
