package com.finki.scheduler.service;

import com.finki.scheduler.domain.*;
import com.finki.scheduler.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TimetableService {

    private final ScheduleSlotRepository slotRepo;
    private final StudyClassRepository   studyClassRepo;
    private final SubjectRepository      subjectRepo;
    private final TeacherRepository      teacherRepo;
    private final ClassroomRepository    classroomRepo;

    public List<ScheduleSlot> getSlots(Short year, String programmeCode,
                                        Long teacherId, Long subjectId,
                                        Long classroomId, LessonType lessonType,
                                        Integer dayOfWeek,
                                        String editionNumber, boolean allEditions) {
        String edition = allEditions ? null
            : (editionNumber != null ? editionNumber : currentEdition());
        return slotRepo.findFiltered(edition, year, programmeCode, teacherId,
            subjectId, classroomId, lessonType, dayOfWeek);
    }

    public String currentEdition() {
        return slotRepo.findDistinctEditionNumbers().stream()
            .max(Comparator.comparingInt(this::editionAsInt))
            .orElse(null);
    }

    public List<String> getEditions() {
        return slotRepo.findDistinctEditionNumbers().stream()
            .sorted(Comparator.comparingInt(this::editionAsInt).reversed())
            .toList();
    }

    private int editionAsInt(String s) {
        try { return Integer.parseInt(s); } catch (NumberFormatException e) { return -1; }
    }

    public List<String> getDistinctProgrammes() {
        return studyClassRepo.findDistinctProgrammeCodes();
    }

    public List<Short> getDistinctYears() {
        return studyClassRepo.findDistinctYears();
    }

    public List<Subject> getAllSubjects() {
        return subjectRepo.findAll();
    }

    public List<Teacher> getAllTeachers() {
        return teacherRepo.findAll();
    }

    public List<Classroom> getAllClassrooms() {
        return classroomRepo.findAll();
    }
}
