package com.finki.scheduler.service.ingestion;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.finki.scheduler.domain.*;
import com.finki.scheduler.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * Ingests the FINKI class timetable from the EduPage regulartt RPC endpoint.
 *
 * Two-step HTTP flow:
 *   1. GET /timetable/  → establishes PHPSESSID session cookie
 *   2. POST getTTViewerData  → discovers the current active edition number
 *   3. POST regularttGetData  → fetches all timetable tables
 *
 * All data is stored in data_rows (not rows) inside each table entry.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class EduPageIngestionService {

    @Value("${edupage.base-url}")
    private String baseUrl;
    @Value("${edupage.gsh}")
    private String gsh;
    @Value("${edupage.edition-year}")
    private String editionYear;

    private final ClassroomRepository classroomRepo;
    private final SubjectRepository subjectRepo;
    private final StudyClassRepository studyClassRepo;
    private final TeacherRepository teacherRepo;
    private final ScheduleSlotRepository slotRepo;
    private final IngestionLogRepository logRepo;
    private final ObjectMapper objectMapper;

    private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("H:mm");

    /**
     * Full timetable ingestion. Returns the number of cards stored.
     * On zero cards, logs a health alert.
     */
    @Transactional
    public int ingest() {
        IngestionLog entry = logRepo.save(IngestionLog.builder()
            .source(IngestionLog.Source.TIMETABLE)
            .status(IngestionLog.Status.RUNNING)
            .build());

        try {
            HttpClient client = HttpClient.newBuilder()
                .cookieHandler(new java.net.CookieManager(null, java.net.CookiePolicy.ACCEPT_ALL))
                .build();

            // Step 1: establish session
            warmSession(client);

            // Step 2: discover current edition
            String editionNum = discoverEdition(client);
            log.info("Ingesting EduPage timetable edition {}", editionNum);

            // Step 3: fetch timetable data
            JsonNode tables = fetchTimetableData(client, editionNum);

            // Step 4: parse and persist
            Map<String, LocalTime[]> periods = parsePeriods(tables);
            Map<String, Classroom> classrooms = upsertClassrooms(tables);
            Map<String, Subject> subjects = upsertSubjects(tables);
            Map<String, StudyClass> classes = upsertStudyClasses(tables);
            Map<String, Teacher> teachers = upsertTeachers(tables);
            int count = upsertCards(tables, periods, subjects, classrooms, teachers, classes, editionNum);

            if (count == 0) {
                log.error("HEALTH ALERT: EduPage ingestion returned 0 cards for edition {}. " +
                    "The endpoint may have changed or the edition number is stale.", editionNum);
            }

            entry.setEditionNumber(editionNum);
            entry.setStatus(IngestionLog.Status.SUCCESS);
            entry.setRecordCount(count);
            entry.setCompletedAt(java.time.Instant.now());
            logRepo.save(entry);
            return count;

        } catch (Exception e) {
            log.error("EduPage ingestion failed", e);
            entry.setStatus(IngestionLog.Status.FAILURE);
            entry.setErrorMessage(e.getMessage());
            entry.setCompletedAt(java.time.Instant.now());
            logRepo.save(entry);
            throw new RuntimeException("EduPage ingestion failed: " + e.getMessage(), e);
        }
    }

    private void warmSession(HttpClient client) throws Exception {
        HttpRequest req = HttpRequest.newBuilder()
            .uri(URI.create(baseUrl + "/timetable/"))
            .header("User-Agent", "FINKIApp/1.0 (student schedule aggregator)")
            .GET().build();
        client.send(req, HttpResponse.BodyHandlers.discarding());
    }

    private String discoverEdition(HttpClient client) throws Exception {
        String body = objectMapper.writeValueAsString(Map.of(
            "__args", List.of(null, editionYear),
            "__gsh", gsh
        ));
        HttpRequest req = HttpRequest.newBuilder()
            .uri(URI.create(baseUrl + "/timetable/server/ttviewer.js?__func=getTTViewerData"))
            .header("Content-Type", "application/json;charset=UTF-8")
            .header("Referer", baseUrl + "/timetable/")
            .POST(HttpRequest.BodyPublishers.ofString(body))
            .build();

        String response = client.send(req, HttpResponse.BodyHandlers.ofString()).body();
        JsonNode root = objectMapper.readTree(response);

        if (root.has("reload") && root.get("reload").asBoolean()) {
            throw new RuntimeException("EduPage session expired; reload=true");
        }
        return root.path("r").path("regular").path("default_num").asText();
    }

    private JsonNode fetchTimetableData(HttpClient client, String editionNum) throws Exception {
        String body = objectMapper.writeValueAsString(Map.of(
            "__args", List.of(null, editionNum),
            "__gsh", gsh
        ));
        HttpRequest req = HttpRequest.newBuilder()
            .uri(URI.create(baseUrl + "/timetable/server/regulartt.js?__func=regularttGetData"))
            .header("Content-Type", "application/json;charset=UTF-8")
            .header("Referer", baseUrl + "/timetable/")
            .POST(HttpRequest.BodyPublishers.ofString(body))
            .build();

        String response = client.send(req, HttpResponse.BodyHandlers.ofString()).body();
        JsonNode root = objectMapper.readTree(response);

        if (root.has("reload") && root.get("reload").asBoolean()) {
            throw new RuntimeException("EduPage returned reload=true on regularttGetData");
        }

        JsonNode tables = root.path("r").path("dbiAccessorRes").path("tables");
        if (!tables.isArray()) {
            throw new RuntimeException("Unexpected response shape: tables is not an array");
        }
        return tables;
    }

    // ── Period lookup ─────────────────────────────────────────────────────────

    private Map<String, LocalTime[]> parsePeriods(JsonNode tables) {
        Map<String, LocalTime[]> map = new LinkedHashMap<>();
        dataRows(tables, "periods").forEach(p -> {
            String id = p.path("id").asText();
            LocalTime start = LocalTime.parse(p.path("starttime").asText(), TIME_FMT);
            LocalTime end   = LocalTime.parse(p.path("endtime").asText(),   TIME_FMT);
            map.put(id, new LocalTime[]{start, end});
        });
        return map;
    }

    // ── Classrooms ────────────────────────────────────────────────────────────

    private Map<String, Classroom> upsertClassrooms(JsonNode tables) {
        Map<String, Classroom> map = new HashMap<>();
        dataRows(tables, "classrooms").forEach(row -> {
            String eid = row.path("id").asText();
            Classroom c = classroomRepo.findByEdupageId(eid).orElseGet(() ->
                Classroom.builder().edupageId(eid).build());
            c.setName(row.path("name").asText());
            c.setShortName(row.path("short").asText(null));
            map.put(eid, classroomRepo.save(c));
        });
        return map;
    }

    // ── Subjects ──────────────────────────────────────────────────────────────

    private Map<String, Subject> upsertSubjects(JsonNode tables) {
        Map<String, Subject> map = new HashMap<>();
        dataRows(tables, "subjects").forEach(row -> {
            String eid = row.path("id").asText();
            String fullName = row.path("name").asText();
            String baseName = extractBaseName(fullName);
            LessonType type = LessonType.fromSuffix(extractSuffix(fullName));

            Subject s = subjectRepo.findByEdupageId(eid).orElseGet(() ->
                Subject.builder().edupageId(eid).build());
            s.setFullName(fullName);
            s.setBaseName(baseName);
            s.setLessonType(type);
            map.put(eid, subjectRepo.save(s));
        });
        return map;
    }

    private String extractSuffix(String name) {
        int open = name.lastIndexOf('(');
        int close = name.lastIndexOf(')');
        if (open >= 0 && close > open) return name.substring(open + 1, close).trim();
        return null;
    }

    private String extractBaseName(String name) {
        int open = name.lastIndexOf('(');
        return open > 0 ? name.substring(0, open).trim() : name.trim();
    }

    // ── Study classes ─────────────────────────────────────────────────────────

    private Map<String, StudyClass> upsertStudyClasses(JsonNode tables) {
        Map<String, StudyClass> map = new HashMap<>();
        dataRows(tables, "classes").forEach(row -> {
            String eid  = row.path("id").asText();
            String name = row.path("name").asText();
            String colour = row.path("color").asText(null);

            StudyClass sc = studyClassRepo.findByEdupageId(eid).orElseGet(() ->
                StudyClass.builder().edupageId(eid).build());
            sc.setName(name);
            sc.setColour(colour);
            sc.setYear(parseYear(name));
            sc.setProgrammeCode(parseProgramme(name));
            map.put(eid, studyClassRepo.save(sc));
        });
        return map;
    }

    // "1г-СИИС" → year=1;  "2y-SEIS" → year=2
    private Short parseYear(String name) {
        if (name == null || name.isEmpty()) return null;
        char first = name.charAt(0);
        if (first >= '1' && first <= '4') return (short)(first - '0');
        return null;
    }

    // "1г-СИИС" → "СИИС";  "1г-ПИТ-1" → "ПИТ";  "2y-SEIS" → "SEIS"
    private String parseProgramme(String name) {
        if (name == null) return null;
        // Strip leading "Nг-" or "Ny-"
        int sep = name.indexOf('-');
        if (sep < 0) return null;
        String rest = name.substring(sep + 1);
        // If there's another dash (like ПИТ-1), take only the first segment
        int nextDash = rest.indexOf('-');
        return nextDash > 0 ? rest.substring(0, nextDash) : rest;
    }

    // ── Teachers ──────────────────────────────────────────────────────────────

    private Map<String, Teacher> upsertTeachers(JsonNode tables) {
        Map<String, Teacher> map = new HashMap<>();
        dataRows(tables, "teachers").forEach(row -> {
            String eid  = row.path("id").asText();
            String name = row.path("short").asText();

            Teacher t = teacherRepo.findByEdupageId(eid).orElseGet(() ->
                Teacher.builder().edupageId(eid).build());
            t.setCyrillicName(name);
            map.put(eid, teacherRepo.save(t));
        });
        return map;
    }

    // ── Cards ─────────────────────────────────────────────────────────────────

    @SuppressWarnings("java:S3776")
    private int upsertCards(JsonNode tables,
                            Map<String, LocalTime[]> periods,
                            Map<String, Subject> subjects,
                            Map<String, Classroom> classrooms,
                            Map<String, Teacher> teachers,
                            Map<String, StudyClass> classes,
                            String editionNum) {
        // Build a lesson lookup
        Map<String, JsonNode> lessons = new HashMap<>();
        dataRows(tables, "lessons").forEach(l -> lessons.put(l.path("id").asText(), l));

        // Sort period IDs numerically so duration lookup works
        List<String> sortedPeriodIds = new ArrayList<>(periods.keySet());
        sortedPeriodIds.sort(Comparator.comparingInt(id -> {
            try { return Integer.parseInt(id); } catch (NumberFormatException e) { return 0; }
        }));

        int count = 0;
        for (JsonNode card : dataRows(tables, "cards")) {
            try {
                String cardId   = card.path("id").asText();
                String lessonId = card.path("lessonid").asText();
                JsonNode lesson = lessons.get(lessonId);
                if (lesson == null) {
                    log.debug("Card {} references unknown lesson {}", cardId, lessonId);
                    continue;
                }

                // Day: bitmask like "01000" → day index 1 (Tuesday)
                String dayBits = card.path("days").asText("");
                int dayOfWeek = dayBits.indexOf('1');
                if (dayOfWeek < 0) continue; // unscheduled card

                // Times
                String startPeriodId = card.path("period").asText();
                LocalTime[] startPeriod = periods.get(startPeriodId);
                if (startPeriod == null) continue;

                int duration = lesson.path("durationperiods").asInt(1);
                int startIdx = sortedPeriodIds.indexOf(startPeriodId);
                int endIdx   = Math.min(startIdx + duration - 1, sortedPeriodIds.size() - 1);
                LocalTime endTime = periods.get(sortedPeriodIds.get(endIdx))[1];

                // Subject
                Subject subject = subjects.get(lesson.path("subjectid").asText());
                if (subject == null) continue;

                // Classroom (first one only for multi-room cards)
                Classroom classroom = null;
                JsonNode roomIds = card.path("classroomids");
                if (roomIds.isArray() && !roomIds.isEmpty()) {
                    classroom = classrooms.get(roomIds.get(0).asText());
                }

                // Build or update slot
                ScheduleSlot slot = slotRepo.findByEdupageCardId(cardId).orElseGet(() ->
                    ScheduleSlot.builder().edupageCardId(cardId).build());
                slot.setSubject(subject);
                slot.setClassroom(classroom);
                slot.setDayOfWeek(dayOfWeek);
                slot.setStartTime(startPeriod[0]);
                slot.setEndTime(endTime);
                slot.setEditionNumber(editionNum);

                // Teachers
                Set<Teacher> slotTeachers = new HashSet<>();
                lesson.path("teacherids").forEach(tid ->
                    Optional.ofNullable(teachers.get(tid.asText())).ifPresent(slotTeachers::add));
                slot.setTeachers(slotTeachers);

                // Classes
                Set<StudyClass> slotClasses = new HashSet<>();
                lesson.path("classids").forEach(cid ->
                    Optional.ofNullable(classes.get(cid.asText())).ifPresent(slotClasses::add));
                slot.setStudyClasses(slotClasses);

                slotRepo.save(slot);
                count++;

            } catch (Exception e) {
                log.warn("Skipping malformed card: {}", e.getMessage());
            }
        }
        return count;
    }

    // ── Utility ───────────────────────────────────────────────────────────────

    private Iterable<JsonNode> dataRows(JsonNode tables, String tableName) {
        for (JsonNode tbl : tables) {
            if (tableName.equals(tbl.path("id").asText())) {
                JsonNode rows = tbl.path("data_rows");
                if (rows.isArray()) return rows;
            }
        }
        return Collections.emptyList();
    }
}
