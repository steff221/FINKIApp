package com.finki.scheduler.service;

import com.finki.scheduler.domain.Exam;
import com.finki.scheduler.repository.ExamRepository;
import com.finki.scheduler.service.parsing.CsvFields;
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

        String[] lines = CsvFields.lines(csv);
        char delim = CsvFields.delimiterOf(lines[0]);

        List<Exam> out = new ArrayList<>();
        for (int i = 1; i < lines.length; i++) { // skip header row
            String line = lines[i].trim();
            if (line.isEmpty()) continue;

            String[] cols = CsvFields.split(line, delim);
            String subject = CsvFields.col(cols, 0);
            if (subject.isEmpty()) continue; // skip blank/spacer rows

            try {
                out.add(Exam.builder()
                    .session(session)
                    .subjectName(subject)
                    .date(CsvFields.date(CsvFields.col(cols, 1)))
                    .startTime(CsvFields.time(CsvFields.col(cols, 2)))
                    .endTime(CsvFields.time(CsvFields.col(cols, 3)))
                    .rooms(CsvFields.emptyToNull(CsvFields.col(cols, 4)))
                    .note(CsvFields.emptyToNull(CsvFields.col(cols, 5)))
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
