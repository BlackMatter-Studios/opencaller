/// Multilingual profanity and abuse filter for OpenCaller suggestions
/// Supports Spanish, English, Portuguese, and leetspeak/punctuation obfuscation

const PROFANITY_WORDS: &[&str] = &[
    // Spanish
    "puta", "puto", "mierda", "pendejo", "pendeja", "cabron", "cabrona", "verga",
    "hijueputa", "hdp", "concha", "conchetumadre", "culiao", "culia", "maricon",
    "marica", "imbecil", "estupido", "estupida", "zorra", "carechimba", "gonorrea",
    "malparido", "malparida", "chinga", "chingada", "coño", "chucha", "mamaguevo",
    "maldito", "maldita", "pelotudo", "boludo", "tarado",
    // English
    "fuck", "shit", "bitch", "asshole", "bastard", "cunt", "dick", "fucker",
    "nigger", "nigga", "faggot", "motherfucker", "whore", "slut", "pussy",
    // Abuse / Harassment as names
    "scammer", "ladron", "estafador", "ratero", "extorsionador", "robador",
];

/// Checks if a string contains abusive, vulgar, or profane words
pub fn is_profane(raw: &str) -> bool {
    let (cleaned_with_spaces, compacted) = clean_and_normalize(raw);

    // 1. Check compacted version without spaces/punctuation (catches "p.u.t.a", "f.u.c.k", "h-d-p")
    for &bad in PROFANITY_WORDS {
        if compacted.contains(bad) {
            return true;
        }
    }

    // 2. Check individual whitespace tokens
    let words: Vec<&str> = cleaned_with_spaces.split_whitespace().collect();
    for word in words {
        if PROFANITY_WORDS.contains(&word) {
            return true;
        }

        for &bad in PROFANITY_WORDS {
            if word.contains(bad) && bad.len() >= 4 {
                return true;
            }
        }
    }

    false
}

/// Normalizes text by removing accents, symbols, and leetspeak
/// Returns (with_spaces, compacted_without_spaces)
fn clean_and_normalize(raw: &str) -> (String, String) {
    let lower = raw.trim().to_lowercase();
    let mut with_spaces = String::with_capacity(lower.len());
    let mut compacted = String::with_capacity(lower.len());

    for ch in lower.chars() {
        let mapped = match ch {
            'á' | 'à' | 'ä' | 'â' | '4' | '@' => Some('a'),
            'é' | 'è' | 'ë' | 'ê' | '3' => Some('e'),
            'í' | 'ì' | 'ï' | 'î' | '1' | '!' | '|' => Some('i'),
            'ó' | 'ò' | 'ö' | 'ô' | '0' => Some('o'),
            'ú' | 'ù' | 'ü' | 'û' => Some('u'),
            'ñ' => Some('n'),
            '$' | '5' => Some('s'),
            '+' | '7' => Some('t'),
            c if c.is_alphanumeric() => Some(c),
            c if c.is_whitespace() => None,
            _ => None,
        };

        if let Some(c) = mapped {
            with_spaces.push(c);
            compacted.push(c);
        } else {
            with_spaces.push(' ');
        }
    }

    (with_spaces, compacted)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_clean_words() {
        assert!(!is_profane("Restaurante Dooguies"));
        assert!(!is_profane("Banco de Costa Rica"));
        assert!(!is_profane("Dra. Maria Fernandez"));
        assert!(!is_profane("Uber Delivery"));
    }

    #[test]
    fn test_profanity_detected() {
        assert!(is_profane("Puta Mierda"));
        assert!(is_profane("este tipo es un pendejo"));
        assert!(is_profane("Scammer asshole"));
        assert!(is_profane("p.u.t.a"));
        assert!(is_profane("p3nd3jo"));
        assert!(is_profane("H.D.P."));
    }
}
