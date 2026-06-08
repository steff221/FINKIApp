package com.finki.scheduler.service;

import com.finki.scheduler.domain.ConsultationSlot;
import com.finki.scheduler.domain.Teacher;
import com.finki.scheduler.repository.ConsultationSlotRepository;
import com.finki.scheduler.repository.TeacherRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ConsultationService {

    private final TeacherRepository teacherRepo;
    private final ConsultationSlotRepository slotRepo;

    /** All teachers grouped with their upcoming slots. */
    public Map<Teacher, List<ConsultationSlot>> getAllGrouped() {
        List<Teacher> teachers = teacherRepo.findAll();
        return teachers.stream().collect(Collectors.toMap(
            t -> t,
            t -> slotRepo.findByTeacherIdOrderByDateAscStartTimeAsc(t.getId())
        ));
    }

    /** Slots for a single teacher by their consultation username. */
    public List<ConsultationSlot> getSlotsForTeacher(Long teacherId) {
        return slotRepo.findByTeacherIdOrderByDateAscStartTimeAsc(teacherId);
    }

    /** Slots for a single teacher (for inline display next to a timetable slot). */
    public List<ConsultationSlot> getSlotsForTeacherByUsername(String username) {
        return teacherRepo.findByConsultationUsername(username)
            .map(t -> slotRepo.findByTeacherIdOrderByDateAscStartTimeAsc(t.getId()))
            .orElse(List.of());
    }

    /** Simple name search — returns all slots matching the query. */
    public List<ConsultationSlot> search(String query) {
        if (query == null || query.isBlank()) {
            return slotRepo.findAll();
        }
        return slotRepo.searchByTeacherName(query.trim());
    }
}
