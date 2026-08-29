package com.finki.scheduler.controller;

import com.finki.scheduler.domain.ConsultationSlot;
import com.finki.scheduler.domain.Teacher;
import com.finki.scheduler.dto.response.ConsultationSlotResponse;
import com.finki.scheduler.dto.response.TeacherWithSlotsResponse;
import com.finki.scheduler.service.ConsultationService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/consultations")
@RequiredArgsConstructor
public class ConsultationController {

    /** By professor name, blanks last, so the list reads the same on every request. */
    private static final Comparator<TeacherWithSlotsResponse> BY_NAME =
        Comparator.comparing(r -> r.teacher().cyrillicName() != null ? r.teacher().cyrillicName() : "");

    private final ConsultationService consultationService;

    /**
     * The consultations list. Booking totals are read once for every slot rather
     * than one query per slot — the counts are only used to render a number.
     */
    @GetMapping
    public List<TeacherWithSlotsResponse> getAll(@RequestParam(required = false) String q) {
        Map<Long, Long> counts = consultationService.bookingCounts();
        Function<Long, Long> countOf = id -> ConsultationService.bookingCountOf(counts, id);

        Map<Teacher, List<ConsultationSlot>> grouped = (q != null && !q.isBlank())
            ? consultationService.search(q).stream()
                .collect(Collectors.groupingBy(ConsultationSlot::getTeacher))
            : consultationService.getAllGrouped();

        return grouped.entrySet().stream()
            .map(e -> TeacherWithSlotsResponse.from(e.getKey(), e.getValue(), countOf))
            .sorted(BY_NAME)
            .toList();
    }

    @GetMapping("/teacher/{teacherId}")
    public List<ConsultationSlotResponse> getForTeacher(@PathVariable Long teacherId) {
        Map<Long, Long> counts = consultationService.bookingCounts();
        return consultationService.getSlotsForTeacher(teacherId).stream()
            .map(s -> ConsultationSlotResponse.from(s, ConsultationService.bookingCountOf(counts, s.getId())))
            .toList();
    }
}
