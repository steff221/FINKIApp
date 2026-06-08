package com.finki.scheduler.service.matching;

import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Normalises teacher names for fuzzy matching across EduPage (Cyrillic) and
 * consultations (Latin username).
 *
 * Strategy:
 *  1. Transliterate Macedonian Cyrillic → Latin using the standard Macedonian
 *     Latin transliteration (ISO 9 variant used in FINKI usernames).
 *  2. Lowercase everything.
 *  3. Replace dots, underscores, hyphens, and multiple spaces with a single space.
 *  4. Strip any remaining non-ASCII characters.
 */
@Component
public class NameNormalizer {

    // Ordered: multi-char sequences first so Ш doesn't get caught by Ш→sh before Шт→sht etc.
    private static final Map<String, String> CYRILLIC_MAP = new LinkedHashMap<>();

    static {
        // Two-character graphemes (must come before their single-char prefixes)
        CYRILLIC_MAP.put("Ѓ", "gj"); CYRILLIC_MAP.put("ѓ", "gj");
        CYRILLIC_MAP.put("Ќ", "kj"); CYRILLIC_MAP.put("ќ", "kj");
        CYRILLIC_MAP.put("Љ", "lj"); CYRILLIC_MAP.put("љ", "lj");
        CYRILLIC_MAP.put("Њ", "nj"); CYRILLIC_MAP.put("њ", "nj");
        CYRILLIC_MAP.put("Џ", "dzh"); CYRILLIC_MAP.put("џ", "dzh");
        CYRILLIC_MAP.put("Ж", "zh"); CYRILLIC_MAP.put("ж", "zh");
        CYRILLIC_MAP.put("Ш", "sh"); CYRILLIC_MAP.put("ш", "sh");
        CYRILLIC_MAP.put("Ч", "ch"); CYRILLIC_MAP.put("ч", "ch");
        CYRILLIC_MAP.put("Ѕ", "dz"); CYRILLIC_MAP.put("ѕ", "dz");
        // Single-character graphemes
        CYRILLIC_MAP.put("А", "a");  CYRILLIC_MAP.put("а", "a");
        CYRILLIC_MAP.put("Б", "b");  CYRILLIC_MAP.put("б", "b");
        CYRILLIC_MAP.put("В", "v");  CYRILLIC_MAP.put("в", "v");
        CYRILLIC_MAP.put("Г", "g");  CYRILLIC_MAP.put("г", "g");
        CYRILLIC_MAP.put("Д", "d");  CYRILLIC_MAP.put("д", "d");
        CYRILLIC_MAP.put("Е", "e");  CYRILLIC_MAP.put("е", "e");
        CYRILLIC_MAP.put("З", "z");  CYRILLIC_MAP.put("з", "z");
        CYRILLIC_MAP.put("И", "i");  CYRILLIC_MAP.put("и", "i");
        CYRILLIC_MAP.put("Ј", "j");  CYRILLIC_MAP.put("ј", "j");
        CYRILLIC_MAP.put("К", "k");  CYRILLIC_MAP.put("к", "k");
        CYRILLIC_MAP.put("Л", "l");  CYRILLIC_MAP.put("л", "l");
        CYRILLIC_MAP.put("М", "m");  CYRILLIC_MAP.put("м", "m");
        CYRILLIC_MAP.put("Н", "n");  CYRILLIC_MAP.put("н", "n");
        CYRILLIC_MAP.put("О", "o");  CYRILLIC_MAP.put("о", "o");
        CYRILLIC_MAP.put("П", "p");  CYRILLIC_MAP.put("п", "p");
        CYRILLIC_MAP.put("Р", "r");  CYRILLIC_MAP.put("р", "r");
        CYRILLIC_MAP.put("С", "s");  CYRILLIC_MAP.put("с", "s");
        CYRILLIC_MAP.put("Т", "t");  CYRILLIC_MAP.put("т", "t");
        CYRILLIC_MAP.put("У", "u");  CYRILLIC_MAP.put("у", "u");
        CYRILLIC_MAP.put("Ф", "f");  CYRILLIC_MAP.put("ф", "f");
        CYRILLIC_MAP.put("Х", "h");  CYRILLIC_MAP.put("х", "h");
        CYRILLIC_MAP.put("Ц", "c");  CYRILLIC_MAP.put("ц", "c");
    }

    public String normalize(String name) {
        if (name == null) return "";
        String s = transliterate(name);
        s = s.toLowerCase();
        // Usernames use dots as separators (e.g. "igor.mishkovski")
        s = s.replace('.', ' ').replace('_', ' ').replace('-', ' ');
        // Collapse whitespace
        s = s.replaceAll("\\s+", " ").trim();
        // Drop anything that survived (parentheses, digits, etc.)
        s = s.replaceAll("[^a-z ]", "");
        return s.trim();
    }

    private String transliterate(String input) {
        StringBuilder sb = new StringBuilder(input.length() * 2);
        for (int i = 0; i < input.length(); i++) {
            String ch = String.valueOf(input.charAt(i));
            String replacement = CYRILLIC_MAP.get(ch);
            sb.append(replacement != null ? replacement : ch);
        }
        return sb.toString();
    }
}
