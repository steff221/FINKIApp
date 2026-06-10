package com.finki.scheduler.dto.response;

import com.finki.scheduler.domain.ConsultationSlot;
import com.finki.scheduler.domain.Teacher;

import java.util.List;
import java.util.function.Function;

public record TeacherWithSlotsResponse(
    TeacherResponse teacher,
    List<ConsultationSlotResponse> slots
) {
    public static TeacherWithSlotsResponse from(Teacher teacher, List<ConsultationSlot> slots) {
        return from(teacher, slots, id -> 0L);
    }

    public static TeacherWithSlotsResponse from(
            Teacher teacher,
            List<ConsultationSlot> slots,
            Function<Long, Long> countFn) {
        return new TeacherWithSlotsResponse(
            TeacherResponse.from(teacher),
            slots.stream().map(s -> ConsultationSlotResponse.from(s, countFn.apply(s.getId()))).toList()
        );
    }
}
