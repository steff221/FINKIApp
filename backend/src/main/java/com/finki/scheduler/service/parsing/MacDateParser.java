package com.finki.scheduler.service.parsing;

import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;

/**
 * Parses date and time strings from the FINKI consultations site.
 * Date format: "D.M.YYYY (macedonian_day_name)"  e.g. "10.6.2026 (среда)"
 * Time format: "HH:mm - HH:mm"                  e.g. "09:00 - 11:00"
 */
@Component
public class MacDateParser {

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("d.M.yyyy");
    private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("H:mm");

    public LocalDate parseDate(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new IllegalArgumentException("Blank date string");
        }
        // "10.6.2026 (среда)" → strip the parenthetical day name
        String datePart = raw.contains(" ") ? raw.substring(0, raw.indexOf(' ')).trim() : raw.trim();
        try {
            return LocalDate.parse(datePart, DATE_FMT);
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("Cannot parse date: '" + raw + "'", e);
        }
    }

    public LocalTime[] parseTimeRange(String raw) {
        if (raw == null || !raw.contains(" - ")) {
            throw new IllegalArgumentException("Expected 'HH:mm - HH:mm', got: '" + raw + "'");
        }
        String[] parts = raw.split(" - ", 2);
        try {
            return new LocalTime[]{
                LocalTime.parse(parts[0].trim(), TIME_FMT),
                LocalTime.parse(parts[1].trim(), TIME_FMT)
            };
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("Cannot parse time range: '" + raw + "'", e);
        }
    }
}
