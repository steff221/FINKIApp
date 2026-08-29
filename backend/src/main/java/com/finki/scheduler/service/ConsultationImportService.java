package com.finki.scheduler.service;

import com.finki.scheduler.domain.ConsultationSlot;
import com.finki.scheduler.domain.Teacher;
import com.finki.scheduler.repository.ConsultationSlotRepository;
import com.finki.scheduler.repository.TeacherRepository;
import com.finki.scheduler.service.matching.NameNormalizer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * CSV import of professor consultation slots — the replacement for the nightly
 * scrape of consultations.finki.ukim.mk.
 *
 * <p>Expected columns (header row required, order fixed, comma- or
 * semicolon-separated):
 * <pre>professor, date, startTime, endTime, room, instructions</pre>
 * Dates accept YYYY-MM-DD, DD.MM.YYYY or DD/MM/YYYY; times accept HH:mm.
 *
 * <p>The professor column is resolved against teachers already on file, matched
 * on the normalised name — so "Иван Чорбев", "Ivan Chorbev" and "ivan.chorbev"
 * all reach the same row. An unrecognised name fails the whole import instead of
 * creating a teacher: a typo would otherwise fork the roster into two people,
 * and the timetable would keep pointing at the original.
 *
 * <p>An import replaces the slots of every professor named in the file and
 * leaves everyone else untouched, so one file may carry a single professor or
 * the whole faculty. Slots are reconciled rather than wiped: a slot still
 * present in the new file keeps its id, and therefore keeps its bookings.
 * Only slots genuinely absent from the file are deleted — and those take their
 * bookings with them, which is what withdrawing a consultation should mean.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ConsultationImportService {

    private final TeacherRepository teacherRepo;
    private final ConsultationSlotRepository slotRepo;
    private final NameNormalizer nameNormalizer;

    /** What an import did, for the admin response. */
    public record ImportResult(int professors, int slotsStored, int slotsRemoved) {}

    /** One parsed CSV line, before it is tied to a teacher. */
    private record Row(String professor, LocalDate date, LocalTime start, LocalTime end,
                       String room, String instructions) {}

    @Transactional
    public ImportResult importCsv(String csv) {
        List<Row> rows = parse(csv);

        Map<String, Teacher> index = teacherIndex();
        Map<Teacher, List<Row>> byTeacher = new LinkedHashMap<>();
        Set<String> unknown = new LinkedHashSet<>();

        for (Row row : rows) {
            Teacher teacher = index.get(nameNormalizer.normalize(row.professor()));
            if (teacher == null) {
                unknown.add(row.professor());
                continue;
            }
            byTeacher.computeIfAbsent(teacher, t -> new ArrayList<>()).add(row);
        }

        // Report every unrecognised name at once: fixing a CSV one rejected row
        // per upload is a miserable way to spend an afternoon.
        if (!unknown.isEmpty()) {
            throw new IllegalArgumentException(
                "Unrecognised professor(s): " + String.join(", ", unknown)
                + ". Use the name as it appears on the timetable, or the consultation username.");
        }

        int stored = 0;
        int removed = 0;
        for (Map.Entry<Teacher, List<Row>> entry : byTeacher.entrySet()) {
            int[] counts = reconcile(entry.getKey(), entry.getValue());
            stored += counts[0];
            removed += counts[1];
        }

        log.info("Consultation import: {} professors, {} slots stored, {} withdrawn",
            byTeacher.size(), stored, removed);
        return new ImportResult(byTeacher.size(), stored, removed);
    }

    // ── Teacher resolution ────────────────────────────────────────────────────

    /**
     * Every name a teacher can be addressed by, normalised, pointing at that
     * teacher. A key claimed by two different teachers is dropped rather than
     * resolved arbitrarily — the import then rejects it as unrecognised, which
     * is the honest answer when we cannot tell two people apart.
     */
    private Map<String, Teacher> teacherIndex() {
        Map<String, Teacher> index = new HashMap<>();
        Set<String> ambiguous = new HashSet<>();

        for (Teacher teacher : teacherRepo.findAll()) {
            for (String key : keysFor(teacher)) {
                Teacher claimed = index.putIfAbsent(key, teacher);
                if (claimed != null && !claimed.getId().equals(teacher.getId())) {
                    ambiguous.add(key);
                }
            }
        }
        ambiguous.forEach(index::remove);
        return index;
    }

    private Set<String> keysFor(Teacher teacher) {
        Set<String> keys = new LinkedHashSet<>();
        for (String raw : List.of(
                nullToEmpty(teacher.getCyrillicName()),
                nullToEmpty(teacher.getCanonicalName()),
                nullToEmpty(teacher.getConsultationUsername()))) {
            if (raw.isBlank()) continue;
            String key = nameNormalizer.normalize(raw);
            if (!key.isBlank()) keys.add(key);
        }
        return keys;
    }

    // ── Slot reconciliation ───────────────────────────────────────────────────

    /**
     * Brings one teacher's stored slots in line with the rows for them, keyed on
     * date + start time. Returns {stored, removed}.
     */
    private int[] reconcile(Teacher teacher, List<Row> rows) {
        Map<String, ConsultationSlot> existing = new LinkedHashMap<>();
        for (ConsultationSlot slot : slotRepo.findByTeacherIdOrderByDateAscStartTimeAsc(teacher.getId())) {
            existing.put(slotKey(slot.getDate(), slot.getStartTime()), slot);
        }

        Set<String> seen = new LinkedHashSet<>();
        int stored = 0;
        for (Row row : rows) {
            String key = slotKey(row.date(), row.start());
            // A file that lists the same professor at the same hour twice gets
            // the first one; the second is a duplicate, not a second meeting.
            if (!seen.add(key)) continue;

            ConsultationSlot slot = existing.get(key);
            if (slot == null) {
                slot = ConsultationSlot.builder()
                    .teacher(teacher)
                    .date(row.date())
                    .startTime(row.start())
                    .build();
            }
            slot.setEndTime(row.end());
            slot.setRoom(row.room());
            slot.setInstructions(row.instructions());
            slot.setScrapedAt(Instant.now());
            slotRepo.save(slot);
            stored++;
        }

        List<ConsultationSlot> withdrawn = existing.entrySet().stream()
            .filter(e -> !seen.contains(e.getKey()))
            .map(Map.Entry::getValue)
            .toList();
        slotRepo.deleteAll(withdrawn);

        return new int[] {stored, withdrawn.size()};
    }

    private String slotKey(LocalDate date, LocalTime start) {
        return date + "T" + start;
    }

    // ── Parsing ───────────────────────────────────────────────────────────────

    private List<Row> parse(String csv) {
        if (csv == null || csv.isBlank())
            throw new IllegalArgumentException("CSV body is empty");

        String[] lines = csv.replace("﻿", "").split("\\r?\\n");
        char delim = lines[0].contains(";") ? ';' : ',';

        List<Row> out = new ArrayList<>();
        for (int i = 1; i < lines.length; i++) { // skip header row
            String line = lines[i].trim();
            if (line.isEmpty()) continue;

            String[] cols = splitCsv(line, delim);
            String professor = col(cols, 0);
            if (professor.isEmpty()) continue; // blank/spacer row

            try {
                LocalTime start = parseTime(col(cols, 2));
                LocalTime end = parseTime(col(cols, 3));
                if (start == null) throw new IllegalArgumentException("missing start time");
                if (end == null) throw new IllegalArgumentException("missing end time");
                if (!end.isAfter(start))
                    throw new IllegalArgumentException("end time is not after start time");

                out.add(new Row(
                    professor,
                    parseDate(col(cols, 1)),
                    start,
                    end,
                    emptyToNull(col(cols, 4)),
                    emptyToNull(col(cols, 5))));
            } catch (RuntimeException ex) {
                throw new IllegalArgumentException(
                    "Could not parse row " + (i + 1) + ": \"" + line + "\" — " + ex.getMessage());
            }
        }
        if (out.isEmpty())
            throw new IllegalArgumentException("No consultation rows found in CSV");
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

    private String nullToEmpty(String s) {
        return s == null ? "" : s;
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
        String[] p = s.trim().split(":");
        int h = Integer.parseInt(p[0].trim());
        int m = p.length > 1 ? Integer.parseInt(p[1].trim()) : 0;
        return LocalTime.of(h, m);
    }
}
