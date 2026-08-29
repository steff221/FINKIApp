package com.finki.scheduler.service.parsing;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

/**
 * The bits of CSV reading the admin importers share.
 *
 * <p>Both the exam timetable and the consultation slots arrive as a file someone
 * exported from a spreadsheet, which is a narrow and predictable thing: a header
 * row, one record per line, quoted fields where a value contains the delimiter.
 * This is not a general CSV library and should not grow into one — it handles
 * what the faculty actually sends.
 *
 * <p>Kept deliberately lenient about *shape* and strict about *values*: a blank
 * spacer row is skipped by the caller without complaint, but a date that cannot
 * be read throws, so the row is reported rather than stored wrong.
 */
public final class CsvFields {

    private CsvFields() {}

    /** Splits a body into lines, dropping the byte-order mark Excel likes to add. */
    public static String[] lines(String csv) {
        return csv.replace("﻿", "").split("\\r?\\n");
    }

    /**
     * Which delimiter a file uses, judged by its header row. A spreadsheet saved
     * in a locale where the comma is the decimal separator exports semicolons.
     */
    public static char delimiterOf(String headerLine) {
        return headerLine.contains(";") ? ';' : ',';
    }

    /** Splits one line, honouring double-quoted fields and doubled quotes inside them. */
    public static String[] split(String line, char delim) {
        List<String> fields = new ArrayList<>();
        StringBuilder cur = new StringBuilder();
        boolean inQuotes = false;
        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);
            if (c == '"') {
                if (inQuotes && i + 1 < line.length() && line.charAt(i + 1) == '"') {
                    cur.append('"');
                    i++;
                } else {
                    inQuotes = !inQuotes;
                }
            } else if (c == delim && !inQuotes) {
                fields.add(cur.toString().trim());
                cur.setLength(0);
            } else {
                cur.append(c);
            }
        }
        fields.add(cur.toString().trim());
        return fields.toArray(new String[0]);
    }

    /** Column [i], or "" when the row is short — a trailing empty field is often just missing. */
    public static String col(String[] cols, int i) {
        return i < cols.length && cols[i] != null ? cols[i].trim() : "";
    }

    public static String emptyToNull(String s) {
        return s == null || s.isBlank() ? null : s;
    }

    /** A date as YYYY-MM-DD, DD.MM.YYYY or DD/MM/YYYY. Throws if it is none of them. */
    public static LocalDate date(String s) {
        if (s == null || s.isBlank()) throw new IllegalArgumentException("missing date");
        String t = s.trim();
        if (t.contains(".")) return dayMonthYear(t.split("\\."));
        if (t.contains("/")) return dayMonthYear(t.split("/"));
        return LocalDate.parse(t); // ISO
    }

    private static LocalDate dayMonthYear(String[] p) {
        return LocalDate.of(year(p[2]), Integer.parseInt(p[1].trim()), Integer.parseInt(p[0].trim()));
    }

    /** A two-digit year means this century; the faculty writes both. */
    private static int year(String raw) {
        int y = Integer.parseInt(raw.trim());
        return y < 100 ? 2000 + y : y;
    }

    /** A time as HH:mm or HH:mm:ss, or null when the field is empty. */
    public static LocalTime time(String s) {
        if (s == null || s.isBlank()) return null;
        String[] p = s.trim().split(":");
        int h = Integer.parseInt(p[0].trim());
        int m = p.length > 1 ? Integer.parseInt(p[1].trim()) : 0;
        return LocalTime.of(h, m);
    }
}
