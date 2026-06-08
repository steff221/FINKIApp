package com.finki.scheduler.controller;

import com.finki.scheduler.domain.User;
import com.finki.scheduler.dto.response.ScheduleSlotResponse;
import com.finki.scheduler.dto.response.UserScheduleResponse;
import com.finki.scheduler.service.IcsExportService;
import com.finki.scheduler.service.UserScheduleService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/schedule")
@RequiredArgsConstructor
public class ScheduleController {

    private final UserScheduleService scheduleService;
    private final IcsExportService icsExportService;

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

    @GetMapping("/export.ics")
    public ResponseEntity<String> exportIcs(@AuthenticationPrincipal User user) {
        String ics = icsExportService.export(user.getId());
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"finki-schedule.ics\"")
            .contentType(MediaType.parseMediaType("text/calendar"))
            .body(ics);
    }
}
