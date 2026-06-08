package com.finki.scheduler.dto.response;

import com.finki.scheduler.domain.StudyClass;

public record StudyClassResponse(Long id, String name, Short year, String programmeCode) {
    public static StudyClassResponse from(StudyClass sc) {
        return new StudyClassResponse(sc.getId(), sc.getName(), sc.getYear(), sc.getProgrammeCode());
    }
}
