package com.finki.scheduler.service;

import com.finki.scheduler.domain.ScheduleSlot;
import org.junit.jupiter.api.Test;

import java.time.LocalTime;
import java.util.List;

import static org.assertj.core.api.Assertions.*;

class ConflictDetectionTest {

    private static ScheduleSlot slot(long id, int day, String start, String end) {
        ScheduleSlot s = new ScheduleSlot();
        // Use reflection-free setters via Lombok
        s.setId(id);
        s.setDayOfWeek(day);
        s.setStartTime(LocalTime.parse(start));
        s.setEndTime(LocalTime.parse(end));
        return s;
    }

    @Test
    void noConflict_differentDays() {
        var a = slot(1, 0, "08:00", "09:45");  // Monday
        var b = slot(2, 1, "08:00", "09:45");  // Tuesday
        assertThat(UserScheduleService.findConflicts(List.of(a, b))).isEmpty();
    }

    @Test
    void noConflict_adjacent_samDay() {
        var a = slot(1, 0, "08:00", "09:45");
        var b = slot(2, 0, "09:45", "11:30");
        assertThat(UserScheduleService.findConflicts(List.of(a, b))).isEmpty();
    }

    @Test
    void conflict_overlap() {
        var a = slot(1, 0, "08:00", "10:00");
        var b = slot(2, 0, "09:00", "11:00");
        List<long[]> conflicts = UserScheduleService.findConflicts(List.of(a, b));
        assertThat(conflicts).hasSize(1);
        assertThat(conflicts.get(0)).containsExactly(1L, 2L);
    }

    @Test
    void conflict_oneContainsOther() {
        var a = slot(1, 2, "10:00", "13:00");
        var b = slot(2, 2, "10:30", "12:00");
        assertThat(UserScheduleService.findConflicts(List.of(a, b))).hasSize(1);
    }

    @Test
    void multipleConflicts() {
        var a = slot(1, 3, "08:00", "10:00");
        var b = slot(2, 3, "09:00", "11:00");
        var c = slot(3, 3, "09:30", "11:30");
        // a-b overlap, a-c overlap, b-c overlap → 3 conflicts
        assertThat(UserScheduleService.findConflicts(List.of(a, b, c))).hasSize(3);
    }

    @Test
    void noConflict_emptySchedule() {
        assertThat(UserScheduleService.findConflicts(List.of())).isEmpty();
    }

    @Test
    void overlapsMethod_boundary() {
        var a = slot(1, 0, "08:00", "09:00");
        var b = slot(2, 0, "09:00", "10:00");
        // start == end is NOT an overlap (open interval end)
        assertThat(UserScheduleService.overlaps(a, b)).isFalse();
    }
}
