package com.finki.scheduler.service;

import com.finki.scheduler.domain.ConsultationSlot;
import com.finki.scheduler.domain.Teacher;
import com.finki.scheduler.repository.ConsultationBookingRepository;
import com.finki.scheduler.repository.ConsultationSlotRepository;
import com.finki.scheduler.repository.TeacherRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ConsultationService {

    private final TeacherRepository teacherRepo;
    private final ConsultationSlotRepository slotRepo;
    private final ConsultationBookingRepository bookingRepo;

    /**
     * Every teacher with their slots, teachers without any included.
     *
     * <p>Two queries regardless of faculty size: the roster, and every slot with
     * its teacher fetched alongside. It used to be one query per teacher, which
     * on a ~100-professor roster meant ~100 round trips for the screen students
     * open first.
     */
    public Map<Teacher, List<ConsultationSlot>> getAllGrouped() {
        Map<Long, List<ConsultationSlot>> byTeacherId = slotRepo.findAllWithTeacher().stream()
            .collect(Collectors.groupingBy(slot -> slot.getTeacher().getId()));

        Map<Teacher, List<ConsultationSlot>> grouped = new LinkedHashMap<>();
        for (Teacher teacher : teacherRepo.findAll()) {
            grouped.put(teacher, byTeacherId.getOrDefault(teacher.getId(), List.of()));
        }
        return grouped;
    }

    public List<ConsultationSlot> getSlotsForTeacher(Long teacherId) {
        return slotRepo.findByTeacherIdOrderByDateAscStartTimeAsc(teacherId);
    }

    public List<ConsultationSlot> getSlotsForTeacherByUsername(String username) {
        return teacherRepo.findByConsultationUsername(username)
            .map(t -> slotRepo.findByTeacherIdOrderByDateAscStartTimeAsc(t.getId()))
            .orElse(List.of());
    }

    public List<ConsultationSlot> search(String query) {
        if (query == null || query.isBlank()) return slotRepo.findAll();
        return slotRepo.searchByTeacherName(query.trim());
    }

    /**
     * How many students have booked each slot, keyed by slot id, in one query.
     * A slot nobody has booked is absent from the map — callers should read it
     * through {@link #bookingCountOf}.
     */
    public Map<Long, Long> bookingCounts() {
        return bookingRepo.countBookingsPerSlot().stream()
            .collect(Collectors.toMap(
                row -> ((Number) row[0]).longValue(),
                row -> ((Number) row[1]).longValue()));
    }

    /** Reads {@link #bookingCounts()} the safe way: an unbooked slot counts zero. */
    public static long bookingCountOf(Map<Long, Long> counts, Long slotId) {
        Long count = counts.get(slotId);
        return count == null ? 0L : count;
    }

    public long countBookings(Long slotId) {
        return bookingRepo.countBySlotId(slotId);
    }
}
