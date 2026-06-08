package com.finki.scheduler.controller;

import com.finki.scheduler.dto.response.ConsultationSlotResponse;
import com.finki.scheduler.dto.response.TeacherWithSlotsResponse;
import com.finki.scheduler.service.ConsultationService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/consultations")
@RequiredArgsConstructor
public class ConsultationController {

    private final ConsultationService consultationService;

    /** All professors with their upcoming slots, optionally filtered by name. */
    @GetMapping
    public List<TeacherWithSlotsResponse> getAll(@RequestParam(required = false) String q) {
        if (q != null && !q.isBlank()) {
            // Search mode: return flat slots, grouped by teacher on the frontend
            var slots = consultationService.search(q);
            return slots.stream()
                .collect(java.util.stream.Collectors.groupingBy(cs -> cs.getTeacher()))
                .entrySet().stream()
                .map(e -> TeacherWithSlotsResponse.from(e.getKey(), e.getValue()))
                .toList();
        }
        return consultationService.getAllGrouped().entrySet().stream()
            .map(e -> TeacherWithSlotsResponse.from(e.getKey(), e.getValue()))
            .sorted(java.util.Comparator.comparing(r -> r.teacher().cyrillicName() != null
                ? r.teacher().cyrillicName() : ""))
            .toList();
    }

    /** Slots for a specific teacher — used for inline display in schedule builder. */
    @GetMapping("/teacher/{teacherId}")
    public List<ConsultationSlotResponse> getForTeacher(@PathVariable Long teacherId) {
        return consultationService.getSlotsForTeacher(teacherId)
            .stream().map(ConsultationSlotResponse::from).toList();
    }
}
