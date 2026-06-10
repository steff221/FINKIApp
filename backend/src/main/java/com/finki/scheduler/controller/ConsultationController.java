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

    @GetMapping
    public List<TeacherWithSlotsResponse> getAll(@RequestParam(required = false) String q) {
        if (q != null && !q.isBlank()) {
            var slots = consultationService.search(q);
            return slots.stream()
                .collect(java.util.stream.Collectors.groupingBy(cs -> cs.getTeacher()))
                .entrySet().stream()
                .map(e -> TeacherWithSlotsResponse.from(
                    e.getKey(),
                    e.getValue(),
                    consultationService::countBookings))
                .toList();
        }
        return consultationService.getAllGrouped().entrySet().stream()
            .map(e -> TeacherWithSlotsResponse.from(
                e.getKey(),
                e.getValue(),
                consultationService::countBookings))
            .sorted(java.util.Comparator.comparing(r -> r.teacher().cyrillicName() != null
                ? r.teacher().cyrillicName() : ""))
            .toList();
    }

    @GetMapping("/teacher/{teacherId}")
    public List<ConsultationSlotResponse> getForTeacher(@PathVariable Long teacherId) {
        return consultationService.getSlotsForTeacher(teacherId).stream()
            .map(s -> ConsultationSlotResponse.from(s, consultationService.countBookings(s.getId())))
            .toList();
    }
}
