package com.finki.scheduler.controller;

import com.finki.scheduler.domain.LessonType;
import com.finki.scheduler.dto.response.*;
import com.finki.scheduler.service.TimetableService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/timetable")
@RequiredArgsConstructor
public class TimetableController {

    private final TimetableService timetableService;

    @GetMapping("/slots")
    public List<ScheduleSlotResponse> getSlots(
        @RequestParam(required = false) Short year,
        @RequestParam(required = false) String programmeCode,
        @RequestParam(required = false) Long teacherId,
        @RequestParam(required = false) Long subjectId,
        @RequestParam(required = false) Long classroomId,
        @RequestParam(required = false) String lessonType,
        @RequestParam(required = false) Integer dayOfWeek,
        @RequestParam(required = false) String editionNumber,
        @RequestParam(required = false, defaultValue = "false") boolean allEditions
    ) {
        LessonType type = lessonType != null ? LessonType.valueOf(lessonType) : null;
        return timetableService.getSlots(year, programmeCode, teacherId,
                subjectId, classroomId, type, dayOfWeek, editionNumber, allEditions)
            .stream().map(ScheduleSlotResponse::from).toList();
    }

    @GetMapping("/filters")
    public TimetableFiltersResponse getFilters() {
        return new TimetableFiltersResponse(
            timetableService.getDistinctYears(),
            timetableService.getDistinctProgrammes(),
            timetableService.getAllSubjects().stream().map(SubjectResponse::from).toList(),
            timetableService.getAllTeachers().stream().map(TeacherResponse::from).toList(),
            timetableService.getAllClassrooms().stream().map(ClassroomResponse::from).toList(),
            timetableService.getEditions(),
            timetableService.currentEdition()
        );
    }
}
