package com.finki.scheduler.dto.response;

import com.finki.scheduler.domain.CustomScheduleEntry;

public record CustomEntryResponse(
    Long id,
    String title,
    String professor,
    String entryType,
    Integer dayOfWeek,
    String startTime,
    String endTime,
    String room,
    String color
) {
    public static CustomEntryResponse from(CustomScheduleEntry e) {
        return new CustomEntryResponse(
            e.getId(),
            e.getTitle(),
            e.getProfessor(),
            e.getEntryType().name(),
            e.getDayOfWeek(),
            e.getStartTime().toString(),
            e.getEndTime().toString(),
            e.getRoom(),
            e.getColor()
        );
    }
}
