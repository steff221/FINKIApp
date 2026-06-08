package com.finki.scheduler.matching;

import com.finki.scheduler.service.matching.NameNormalizer;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class NameNormalizerTest {

    private final NameNormalizer n = new NameNormalizer();

    @Test
    void cyrillicToLatin_simple() {
        assertThat(n.normalize("Александар Тенев")).isEqualTo("aleksandar tenev");
    }

    @Test
    void cyrillicToLatin_specialChars() {
        // Ѓ→gj, Ќ→kj, Љ→lj, Њ→nj, Ш→sh, Ч→ch, Ж→zh
        assertThat(n.normalize("Ѓорѓи Маџаров")).isEqualTo("gjorgji madzharov");
    }

    @Test
    void username_dotSeparated() {
        assertThat(n.normalize("igor.mishkovski")).isEqualTo("igor mishkovski");
    }

    @Test
    void username_matchesCyrillicNormalized() {
        String fromCyrillic = n.normalize("Игор Мишковски");
        String fromUsername = n.normalize("igor.mishkovski");
        assertThat(fromCyrillic).isEqualTo(fromUsername);
    }

    @Test
    void stripsParentheses() {
        assertThat(n.normalize("Ана Тодоровска (д-р)")).isEqualTo("ana todorovska d r");
    }

    @Test
    void nullReturnsEmpty() {
        assertThat(n.normalize(null)).isEmpty();
    }

    @Test
    void cyrillicToLatin_aleksandra() {
        assertThat(n.normalize("Александра Дединец")).isEqualTo("aleksandra dedinec");
    }
}
