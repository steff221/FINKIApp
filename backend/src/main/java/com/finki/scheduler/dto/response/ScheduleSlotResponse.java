package com.finki.scheduler.dto.response;

import com.finki.scheduler.domain.ScheduleSlot;

import java.time.LocalTime;
import java.util.List;

public record ScheduleSlotResponse(
    Long id,
    SubjectResponse subject,
    List<TeacherResponse> teachers,
    List<StudyClassResponse> studyClasses,
    ClassroomResponse classroom,
    int dayOfWeek,
    LocalTime startTime,
    LocalTime endTime,
    String editionNumber
) {
    public static ScheduleSlotResponse from(ScheduleSlot s) {
        return new ScheduleSlotResponse(
            s.getId(),
            SubjectResponse.from(s.getSubject()),
            s.getTeachers().stream().map(TeacherResponse::from).toList(),
            s.getStudyClasses().stream().map(StudyClassResponse::from).toList(),
            s.getClassroom() != null ? ClassroomResponse.from(s.getClassroom()) : null,
            s.getDayOfWeek(),
            s.getStartTime(),
            s.getEndTime(),
            s.getEditionNumber()
        );
    }
}
