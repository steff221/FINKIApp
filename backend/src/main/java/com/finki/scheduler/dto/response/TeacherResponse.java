package com.finki.scheduler.dto.response;

import com.finki.scheduler.domain.Teacher;

public record TeacherResponse(
    Long id,
    String cyrillicName,
    String canonicalName,
    String consultationUsername
) {
    public static TeacherResponse from(Teacher t) {
        return new TeacherResponse(t.getId(), t.getCyrillicName(),
            t.getCanonicalName(), t.getConsultationUsername());
    }
}
