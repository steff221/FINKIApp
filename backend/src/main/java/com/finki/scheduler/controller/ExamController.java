package com.finki.scheduler.controller;

import com.finki.scheduler.dto.response.ExamResponse;
import com.finki.scheduler.service.ExamService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/exams")
@RequiredArgsConstructor
public class ExamController {

    private final ExamService examService;

    @GetMapping
    public List<ExamResponse> getExams(@RequestParam(required = false) String session,
                                       @RequestParam(required = false) String q) {
        return examService.search(session, q).stream().map(ExamResponse::from).toList();
    }

    @GetMapping("/sessions")
    public List<String> getSessions() {
        return examService.getSessions();
    }

    @GetMapping("/export.ics")
    public ResponseEntity<String> exportIcs(@RequestParam(required = false) String session,
                                            @RequestParam(required = false) String q) {
        String ics = examService.exportIcs(session, q);
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"finki-exams.ics\"")
            .contentType(MediaType.parseMediaType("text/calendar"))
            .body(ics);
    }
}
