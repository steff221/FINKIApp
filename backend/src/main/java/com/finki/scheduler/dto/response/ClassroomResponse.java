package com.finki.scheduler.dto.response;

import com.finki.scheduler.domain.Classroom;

public record ClassroomResponse(Long id, String name, String shortName) {
    public static ClassroomResponse from(Classroom c) {
        return new ClassroomResponse(c.getId(), c.getName(), c.getShortName());
    }
}
