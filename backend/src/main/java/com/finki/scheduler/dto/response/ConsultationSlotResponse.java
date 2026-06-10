package com.finki.scheduler.dto.response;

import com.finki.scheduler.domain.ConsultationSlot;

import java.time.LocalDate;
import java.time.LocalTime;

public record ConsultationSlotResponse(
    Long id,
    TeacherResponse teacher,
    LocalDate date,
    LocalTime startTime,
    LocalTime endTime,
    String room,
    String link,
    String instructions,
    int enrolledCount
) {
    public static ConsultationSlotResponse from(ConsultationSlot cs) {
        return from(cs, 0);
    }

    public static ConsultationSlotResponse from(ConsultationSlot cs, long count) {
        return new ConsultationSlotResponse(
            cs.getId(),
            TeacherResponse.from(cs.getTeacher()),
            cs.getDate(),
            cs.getStartTime(),
            cs.getEndTime(),
            cs.getRoom(),
            cs.getLink(),
            cs.getInstructions(),
            (int) count
        );
    }
}
