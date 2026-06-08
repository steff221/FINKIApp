package com.finki.scheduler.dto.response;

import com.finki.scheduler.domain.Subject;

public record SubjectResponse(Long id, String fullName, String baseName, String lessonType) {
    public static SubjectResponse from(Subject s) {
        return new SubjectResponse(s.getId(), s.getFullName(), s.getBaseName(),
            s.getLessonType().name());
    }
}
