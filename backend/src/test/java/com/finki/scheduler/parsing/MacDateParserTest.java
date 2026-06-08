package com.finki.scheduler.parsing;

import com.finki.scheduler.service.parsing.MacDateParser;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.LocalTime;

import static org.assertj.core.api.Assertions.*;

class MacDateParserTest {

    private final MacDateParser parser = new MacDateParser();

    @Test
    void parseDate_standard() {
        assertThat(parser.parseDate("10.6.2026 (среда)"))
            .isEqualTo(LocalDate.of(2026, 6, 10));
    }

    @Test
    void parseDate_singleDigitDay() {
        assertThat(parser.parseDate("5.1.2026 (понеделник)"))
            .isEqualTo(LocalDate.of(2026, 1, 5));
    }

    @Test
    void parseDate_noParenthetical() {
        assertThat(parser.parseDate("11.6.2026"))
            .isEqualTo(LocalDate.of(2026, 6, 11));
    }

    @Test
    void parseDate_invalid_throws() {
        assertThatThrownBy(() -> parser.parseDate("not-a-date"))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void parseDate_null_throws() {
        assertThatThrownBy(() -> parser.parseDate(null))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void parseTimeRange_standard() {
        LocalTime[] times = parser.parseTimeRange("09:00 - 11:00");
        assertThat(times[0]).isEqualTo(LocalTime.of(9, 0));
        assertThat(times[1]).isEqualTo(LocalTime.of(11, 0));
    }

    @Test
    void parseTimeRange_singleDigitHour() {
        LocalTime[] times = parser.parseTimeRange("8:00 - 9:45");
        assertThat(times[0]).isEqualTo(LocalTime.of(8, 0));
        assertThat(times[1]).isEqualTo(LocalTime.of(9, 45));
    }

    @Test
    void parseTimeRange_invalid_throws() {
        assertThatThrownBy(() -> parser.parseTimeRange("badformat"))
            .isInstanceOf(IllegalArgumentException.class);
    }
}
