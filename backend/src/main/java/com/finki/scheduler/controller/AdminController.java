package com.finki.scheduler.controller;

import com.finki.scheduler.dto.response.TeacherResponse;
import com.finki.scheduler.repository.TeacherRepository;
import com.finki.scheduler.service.ConsultationImportService;
import com.finki.scheduler.service.ExamService;
import com.finki.scheduler.service.ingestion.ScheduledIngestionJob;
import jakarta.validation.constraints.Size;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
import java.util.function.Supplier;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@Validated
public class AdminController {

    /** An exam session is a few thousand rows; anything past this is not a timetable. */
    private static final int MAX_CSV_CHARS = 2_000_000;

    private final ScheduledIngestionJob ingestionJob;
    private final TeacherRepository teacherRepo;
    private final ExamService examService;
    private final ConsultationImportService consultationImportService;

    /** Trigger a timetable re-ingestion. Returns the number of cards stored. */
    @PostMapping("/timetable/refresh")
    public ResponseEntity<Map<String, Object>> refreshTimetable() {
        int count = ingestionJob.runTimetable();
        if (count == -1) {
            return ResponseEntity.accepted()
                .body(Map.of("status", "already_running"));
        }
        return ResponseEntity.ok(Map.of("status", "ok", "cardsIngested", count));
    }

    /**
     * Import consultation slots from CSV. Replaces the slots of every professor
     * named in the file and leaves the rest untouched, so a file may carry one
     * professor or all of them. Send the CSV as the raw request body, e.g.:
     *   curl -H "Authorization: Bearer $TOKEN" -H "Content-Type: text/plain" \
     *        --data-binary @consultations.csv \
     *        "http://localhost:8080/api/admin/consultations/import"
     *
     * Columns: professor, date, startTime, endTime, room, instructions
     */
    @PostMapping(value = "/consultations/import", consumes = "text/plain")
    public ResponseEntity<Map<String, Object>> importConsultations(@RequestBody String csv) {
        if (csv.length() > MAX_CSV_CHARS) {
            throw new ResponseStatusException(HttpStatus.PAYLOAD_TOO_LARGE,
                "CSV exceeds " + MAX_CSV_CHARS + " characters");
        }
        ConsultationImportService.ImportResult result =
            importing(() -> consultationImportService.importCsv(csv));
        return ResponseEntity.ok(Map.of(
            "status", "ok",
            "professors", result.professors(),
            "slotsStored", result.slotsStored(),
            "slotsRemoved", result.slotsRemoved()));
    }

    /** EduPage teachers with no matched consultation profile — review list. */
    @GetMapping("/unmatched-teachers")
    public List<TeacherResponse> unmatchedTeachers() {
        return teacherRepo.findUnmatchedEdupageTeachers()
            .stream().map(TeacherResponse::from).toList();
    }

    /**
     * Import an exam-session timetable from CSV. Replaces any exams already stored
     * for the given session. Send the CSV as the raw request body, e.g.:
     *   curl -H "Authorization: Bearer $TOKEN" -H "Content-Type: text/plain" \
     *        --data-binary @june.csv \
     *        "http://localhost:8080/api/admin/exams/import?session=Јунска%20сесија%202025/26"
     */
    @PostMapping(value = "/exams/import", consumes = "text/plain")
    public ResponseEntity<Map<String, Object>> importExams(
            @RequestParam @Size(max = 200) String session,
            @RequestBody String csv) {
        if (csv.length() > MAX_CSV_CHARS) {
            throw new ResponseStatusException(HttpStatus.PAYLOAD_TOO_LARGE,
                "CSV exceeds " + MAX_CSV_CHARS + " characters");
        }
        int count = importing(() -> examService.importCsv(session, csv));
        return ResponseEntity.ok(Map.of("status", "ok", "session", session, "examsImported", count));
    }

    /**
     * Runs a CSV import, turning a parse complaint into a 400 that still carries
     * the detail.
     *
     * <p>{@link GlobalExceptionHandler} deliberately strips exception text from
     * responses — right for an unexpected failure, where the text is where SQL
     * and file paths leak out; wrong for an import, where "Could not parse row
     * 14 ... missing date" is the entire value of the reply. Both importers
     * raise {@link IllegalArgumentException} with a message written to be read,
     * so it is safe to pass on.
     */
    private <T> T importing(Supplier<T> importer) {
        try {
            return importer.get();
        } catch (IllegalArgumentException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, ex.getMessage());
        }
    }
}
