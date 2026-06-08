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
    String instructions
) {
    public static ConsultationSlotResponse from(ConsultationSlot cs) {
        return new ConsultationSlotResponse(
            cs.getId(),
            TeacherResponse.from(cs.getTeacher()),
            cs.getDate(),
            cs.getStartTime(),
            cs.getEndTime(),
            cs.getRoom(),
            cs.getInstructions()
        );
    }
}
