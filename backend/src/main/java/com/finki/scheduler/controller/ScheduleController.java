package com.finki.scheduler.controller;

import com.finki.scheduler.domain.User;
import com.finki.scheduler.dto.response.ExamResponse;
import com.finki.scheduler.dto.response.ScheduleSlotResponse;
import com.finki.scheduler.dto.response.UserScheduleResponse;
import com.finki.scheduler.repository.UserRepository;
import com.finki.scheduler.service.IcsExportService;
import com.finki.scheduler.service.SavedExamService;
import com.finki.scheduler.service.UserScheduleService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/schedule")
@RequiredArgsConstructor
public class ScheduleController {

    private final UserScheduleService scheduleService;
    private final SavedExamService savedExamService;
    private final IcsExportService icsExportService;
    private final UserRepository userRepo;

    @GetMapping
    public UserScheduleResponse getSchedule(@AuthenticationPrincipal User user) {
        List<ScheduleSlotResponse> slots = scheduleService.getSchedule(user.getId())
            .stream().map(ScheduleSlotResponse::from).toList();
        List<long[]> conflicts = scheduleService.detectConflicts(user.getId());
        return new UserScheduleResponse(slots, conflicts);
    }

    @PostMapping("/slots/{slotId}")
    public ResponseEntity<Void> addSlot(@AuthenticationPrincipal User user,
                                         @PathVariable Long slotId) {
        scheduleService.addSlot(user.getId(), slotId);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/slots/{slotId}")
    public ResponseEntity<Void> removeSlot(@AuthenticationPrincipal User user,
                                            @PathVariable Long slotId) {
        scheduleService.removeSlot(user.getId(), slotId);
        return ResponseEntity.noContent().build();
    }

    // ── Saved exams (pinned to Мој Распоред) ──────────────────────────────────

    @GetMapping("/exams")
    public List<ExamResponse> getSavedExams(@AuthenticationPrincipal User user) {
        return savedExamService.getSavedExams(user.getId())
            .stream().map(ExamResponse::from).toList();
    }

    @PostMapping("/exams/{examId}")
    public ResponseEntity<Void> addExam(@AuthenticationPrincipal User user,
                                         @PathVariable Long examId) {
        savedExamService.addExam(user.getId(), examId);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/exams/{examId}")
    public ResponseEntity<Void> removeExam(@AuthenticationPrincipal User user,
                                            @PathVariable Long examId) {
        savedExamService.removeExam(user.getId(), examId);
        return ResponseEntity.noContent().build();
    }

    /**
     * Return (creating on first use) the opaque token that authenticates this
     * user's personal .ics feed, so the calendar URL never carries their JWT.
     */
    @GetMapping("/ics-token")
    public Map<String, String> icsToken(@AuthenticationPrincipal User user) {
        User u = userRepo.findById(user.getId())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
        if (u.getCalendarToken() == null) {
            u.setCalendarToken(UUID.randomUUID().toString().replace("-", ""));
            userRepo.save(u);
        }
        return Map.of("token", u.getCalendarToken());
    }

    /** Public .ics feed, authenticated by the opaque calendar token (not the JWT). */
    @GetMapping("/export.ics")
    public ResponseEntity<String> exportIcs(@RequestParam String token) {
        User user = userRepo.findByCalendarToken(token)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid calendar token"));
        String ics = icsExportService.export(user.getId());
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"finki-schedule.ics\"")
            .contentType(MediaType.parseMediaType("text/calendar"))
            .body(ics);
    }
}
