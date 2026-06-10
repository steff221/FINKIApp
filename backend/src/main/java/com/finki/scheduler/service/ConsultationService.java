package com.finki.scheduler.service;

import com.finki.scheduler.domain.ConsultationSlot;
import com.finki.scheduler.domain.Teacher;
import com.finki.scheduler.repository.ConsultationBookingRepository;
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
    private final ConsultationBookingRepository bookingRepo;

    public Map<Teacher, List<ConsultationSlot>> getAllGrouped() {
        List<Teacher> teachers = teacherRepo.findAll();
        return teachers.stream().collect(Collectors.toMap(
            t -> t,
            t -> slotRepo.findByTeacherIdOrderByDateAscStartTimeAsc(t.getId())
        ));
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

    public long countBookings(Long slotId) {
        return bookingRepo.countBySlotId(slotId);
    }
}
