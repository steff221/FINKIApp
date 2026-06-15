package com.finki.scheduler.service;

import com.finki.scheduler.domain.Exam;
import com.finki.scheduler.repository.ExamRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * Querying, CSV import and .ics export for {@link Exam} session timetables.
 *
 * Expected CSV columns (header row required, order fixed, comma- or semicolon-separated):
 *   subject, date, startTime, endTime, rooms, note
 * Dates accept YYYY-MM-DD, DD.MM.YYYY or DD/MM/YYYY; times accept HH:mm or HH:mm:ss.
 * Importing a session replaces any rows already stored for that session.
 */
@Service
@RequiredArgsConstructor
public class ExamService {

    private static final DateTimeFormatter ICS_DT  = DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss");
    private static final DateTimeFormatter ICS_UTC = DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss'Z'");
    private static final ZoneId SKOPJE = ZoneId.of("Europe/Skopje");

    private final ExamRepository examRepo;

    @Transactional(readOnly = true)
    public List<Exam> search(String session, String q) {
        String s = (session != null && !session.isBlank()) ? session : null;
        String query = (q != null && !q.isBlank()) ? q.trim() : null;
        return examRepo.search(s, query);
    }

    @Transactional(readOnly = true)
    public List<String> getSessions() {
        return examRepo.findDistinctSessions();
    }

    /** Replaces all exams for {@code session} with the parsed CSV rows. Returns the count stored. */
    @Transactional
    public int importCsv(String session, String csv) {
        if (session == null || session.isBlank())
            throw new IllegalArgumentException("session is required");

        List<Exam> parsed = parse(session.trim(), csv);
        examRepo.deleteBySession(session.trim());
        examRepo.saveAll(parsed);
        return parsed.size();
    }

    private List<Exam> parse(String session, String csv) {
        if (csv == null || csv.isBlank())
            throw new IllegalArgumentException("CSV body is empty");

        String[] lines = csv.replace("﻿", "").split("\\r?\\n");
        char delim = lines[0].contains(";") ? ';' : ',';

        List<Exam> out = new ArrayList<>();
        for (int i = 1; i < lines.length; i++) { // skip header row
            String line = lines[i].trim();
            if (line.isEmpty()) continue;

            String[] cols = splitCsv(line, delim);
            String subject = col(cols, 0);
            if (subject.isEmpty()) continue; // skip blank/spacer rows

            try {
                out.add(Exam.builder()
                    .session(session)
                    .subjectName(subject)
                    .date(parseDate(col(cols, 1)))
                    .startTime(parseTime(col(cols, 2)))
                    .endTime(parseTime(col(cols, 3)))
                    .rooms(emptyToNull(col(cols, 4)))
                    .note(emptyToNull(col(cols, 5)))
                    .build());
            } catch (RuntimeException ex) {
                throw new IllegalArgumentException(
                    "Could not parse row " + (i + 1) + ": \"" + line + "\" — " + ex.getMessage());
            }
        }
        if (out.isEmpty())
            throw new IllegalArgumentException("No exam rows found in CSV");
        return out;
    }

    /** Minimal CSV split honouring double-quoted fields. */
    private String[] splitCsv(String line, char delim) {
        List<String> fields = new ArrayList<>();
        StringBuilder cur = new StringBuilder();
        boolean inQuotes = false;
        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);
            if (c == '"') {
                if (inQuotes && i + 1 < line.length() && line.charAt(i + 1) == '"') {
                    cur.append('"'); i++;
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

    private String col(String[] cols, int i) {
        return i < cols.length && cols[i] != null ? cols[i].trim() : "";
    }

    private String emptyToNull(String s) {
        return s == null || s.isBlank() ? null : s;
    }

    private LocalDate parseDate(String s) {
        if (s == null || s.isBlank())
            throw new IllegalArgumentException("missing date");
        s = s.trim();
        if (s.contains(".")) {
            String[] p = s.split("\\.");
            return LocalDate.of(pad4(p[2]), Integer.parseInt(p[1].trim()), Integer.parseInt(p[0].trim()));
        }
        if (s.contains("/")) {
            String[] p = s.split("/");
            return LocalDate.of(pad4(p[2]), Integer.parseInt(p[1].trim()), Integer.parseInt(p[0].trim()));
        }
        return LocalDate.parse(s); // ISO YYYY-MM-DD
    }

    private int pad4(String year) {
        int y = Integer.parseInt(year.trim());
        return y < 100 ? 2000 + y : y;
    }

    private LocalTime parseTime(String s) {
        if (s == null || s.isBlank()) return null;
        s = s.trim();
        String[] p = s.split(":");
        int h = Integer.parseInt(p[0].trim());
        int m = p.length > 1 ? Integer.parseInt(p[1].trim()) : 0;
        return LocalTime.of(h, m);
    }

    // ── ICS export ──────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public String exportIcs(String session, String q) {
        List<Exam> exams = search(session, q);
        String dtStamp = ICS_UTC.format(ZonedDateTime.now(ZoneOffset.UTC));

        StringBuilder sb = new StringBuilder();
        sb.append("BEGIN:VCALENDAR\r\n");
        sb.append("VERSION:2.0\r\n");
        sb.append("PRODID:-//FINKIApp//Exams//EN\r\n");
        sb.append("CALSCALE:GREGORIAN\r\n");
        sb.append("METHOD:PUBLISH\r\n");

        for (Exam e : exams) {
            LocalTime start = e.getStartTime() != null ? e.getStartTime() : LocalTime.of(9, 0);
            LocalTime end   = e.getEndTime()   != null ? e.getEndTime()
                            : (e.getStartTime() != null ? e.getStartTime().plusHours(2) : LocalTime.of(11, 0));

            ZonedDateTime dtStart = ZonedDateTime.of(e.getDate(), start, SKOPJE);
            ZonedDateTime dtEnd   = ZonedDateTime.of(e.getDate(), end,   SKOPJE);

            sb.append("BEGIN:VEVENT\r\n");
            sb.append("UID:exam-").append(e.getId()).append("@finki-scheduler\r\n");
            sb.append("DTSTAMP:").append(dtStamp).append("\r\n");
            sb.append("DTSTART;TZID=Europe/Skopje:").append(dtStart.format(ICS_DT)).append("\r\n");
            sb.append("DTEND;TZID=Europe/Skopje:").append(dtEnd.format(ICS_DT)).append("\r\n");
            sb.append("SUMMARY:").append(escape("Испит: " + e.getSubjectName())).append("\r\n");
            if (e.getRooms() != null && !e.getRooms().isBlank())
                sb.append("LOCATION:").append(escape(e.getRooms())).append("\r\n");
            if (e.getNote() != null && !e.getNote().isBlank())
                sb.append("DESCRIPTION:").append(escape(e.getNote())).append("\r\n");
            sb.append("END:VEVENT\r\n");
        }

        sb.append("END:VCALENDAR\r\n");
        return sb.toString();
    }

    private String escape(String s) {
        return s.replace("\\", "\\\\")
                .replace(";", "\\;")
                .replace(",", "\\,")
                .replace("\r\n", "\\n")
                .replace("\r", "\\n")
                .replace("\n", "\\n");
    }
}
