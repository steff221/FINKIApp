package com.finki.scheduler.matching;

import com.finki.scheduler.service.matching.NameNormalizer;
import com.finki.scheduler.service.matching.TeacherMatcherService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class TeacherMatcherTest {

    private TeacherMatcherService matcher;
    private NameNormalizer normalizer;

    @BeforeEach
    void setUp() {
        normalizer = new NameNormalizer();
        // TeacherMatcherService needs repos; we test only the similarity method directly
        // since it's public and repo-independent
        matcher = new TeacherMatcherService(null, null, normalizer);
    }

    @Test
    void exactMatch() {
        String a = normalizer.normalize("Игор Мишковски");
        String b = normalizer.normalize("igor.mishkovski");
        assertThat(matcher.similarity(a, b)).isEqualTo(1.0);
    }

    @Test
    void closeMatch_highConfidence() {
        // Slight abbreviation or middle-name difference
        String a = normalizer.normalize("Александар Тенев");
        String b = normalizer.normalize("aleksandar.tenev");
        assertThat(matcher.similarity(a, b)).isGreaterThanOrEqualTo(0.85);
    }

    @Test
    void differentNames_lowSimilarity() {
        String a = normalizer.normalize("Зоран Петров");
        String b = normalizer.normalize("ana.todorovska");
        assertThat(matcher.similarity(a, b)).isLessThan(0.5);
    }

    @Test
    void emptyStrings() {
        assertThat(matcher.similarity("", "")).isEqualTo(1.0);
        assertThat(matcher.similarity("abc", "")).isEqualTo(0.0);
    }

    @Test
    void realFINKIProfessors_fuzzyMatch() {
        // Full name has three tokens; username has two — similarity must be high enough to match
        String fromName     = normalizer.normalize("Билјана Тојтовска Рибарски");
        String fromUsername = normalizer.normalize("biljana.tojtovska");
        // Both start with "biljana tojtovska" — similarity should be well above low threshold
        assertThat(matcher.similarity(fromName, fromUsername)).isGreaterThan(0.6);
    }

    // --- Token-set similarity: robust to word order and extra name tokens ---

    @Test
    void tokenSet_extraSurname_isTreatedAsSubset() {
        // The maiden/second surname "рибарски" is present on one side only. Whole-string
        // Levenshtein is dragged down by it; token-set treats it as a subset → ~1.0.
        String fromName     = normalizer.normalize("Билјана Тојтовска Рибарски");
        String fromUsername = normalizer.normalize("biljana.tojtovska");
        assertThat(matcher.tokenSetSimilarity(fromName, fromUsername)).isGreaterThanOrEqualTo(0.99);
    }

    @Test
    void tokenSet_reorderedTokens_scoreFull() {
        // Surname-first vs given-name-first must not be penalised.
        String a = normalizer.normalize("Петров Зоран");
        String b = normalizer.normalize("zoran.petrov");
        assertThat(matcher.tokenSetSimilarity(a, b)).isEqualTo(1.0);
    }

    @Test
    void tokenSet_sharedFirstNameOnly_staysBelowMatchThreshold() {
        // Two different people who merely share a first name must not match.
        String a = normalizer.normalize("Ана Тодоровска");
        String b = normalizer.normalize("ana.petrova");
        assertThat(matcher.tokenSetSimilarity(a, b)).isLessThan(0.6);
    }

    @Test
    void tokenSet_emptyStrings() {
        assertThat(matcher.tokenSetSimilarity("", "")).isEqualTo(1.0);
        assertThat(matcher.tokenSetSimilarity("abc", "")).isEqualTo(0.0);
    }
}
