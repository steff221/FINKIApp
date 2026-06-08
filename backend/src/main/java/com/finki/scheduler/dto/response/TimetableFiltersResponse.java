package com.finki.scheduler.dto.response;

import java.util.List;

public record TimetableFiltersResponse(
    List<Short>  years,
    List<String> programmes,
    List<SubjectResponse>   subjects,
    List<TeacherResponse>   teachers,
    List<ClassroomResponse> classrooms
) {}
