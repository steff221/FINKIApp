package com.finki.scheduler.dto.response;

import com.finki.scheduler.domain.Exam;

import java.time.LocalDate;
import java.time.LocalTime;

public record ExamResponse(
    Long id,
    String session,
    String subjectName,
    LocalDate date,
    LocalTime startTime,
    LocalTime endTime,
    String rooms,
    String note
) {
    public static ExamResponse from(Exam e) {
        return new ExamResponse(
            e.getId(),
            e.getSession(),
            e.getSubjectName(),
            e.getDate(),
            e.getStartTime(),
            e.getEndTime(),
            e.getRooms(),
            e.getNote()
        );
    }
}
