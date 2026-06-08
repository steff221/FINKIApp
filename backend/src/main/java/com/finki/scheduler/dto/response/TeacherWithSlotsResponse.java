package com.finki.scheduler.dto.response;

import com.finki.scheduler.domain.ConsultationSlot;
import com.finki.scheduler.domain.Teacher;

import java.util.List;

public record TeacherWithSlotsResponse(
    TeacherResponse teacher,
    List<ConsultationSlotResponse> slots
) {
    public static TeacherWithSlotsResponse from(Teacher teacher, List<ConsultationSlot> slots) {
        return new TeacherWithSlotsResponse(
            TeacherResponse.from(teacher),
            slots.stream().map(ConsultationSlotResponse::from).toList()
        );
    }
}
