package com.finki.scheduler.controller;

import com.finki.scheduler.dto.response.TeacherResponse;
import com.finki.scheduler.repository.TeacherRepository;
import com.finki.scheduler.service.ingestion.ScheduledIngestionJob;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final ScheduledIngestionJob ingestionJob;
    private final TeacherRepository teacherRepo;

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

    /** Trigger a consultations re-scrape. */
    @PostMapping("/consultations/refresh")
    public ResponseEntity<Map<String, Object>> refreshConsultations() {
        int count = ingestionJob.runConsultations();
        if (count == -1) {
            return ResponseEntity.accepted()
                .body(Map.of("status", "already_running"));
        }
        return ResponseEntity.ok(Map.of("status", "ok", "slotsScraped", count));
    }

    /** EduPage teachers with no matched consultation profile — review list. */
    @GetMapping("/unmatched-teachers")
    public List<TeacherResponse> unmatchedTeachers() {
        return teacherRepo.findUnmatchedEdupageTeachers()
            .stream().map(TeacherResponse::from).toList();
    }
}
