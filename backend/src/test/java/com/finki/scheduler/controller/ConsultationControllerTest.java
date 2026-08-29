package com.finki.scheduler.controller;

import com.finki.scheduler.domain.ConsultationSlot;
import com.finki.scheduler.domain.Teacher;
import com.finki.scheduler.dto.response.TeacherWithSlotsResponse;
import com.finki.scheduler.service.ConsultationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ConsultationControllerTest {

    @Mock private ConsultationService consultationService;

    private ConsultationController controller;

    private final Teacher chorbev = Teacher.builder().id(1L).cyrillicName("Иван Чорбев").build();
    private final Teacher antovski = Teacher.builder().id(2L).cyrillicName("Александар Антовски").build();

    @BeforeEach
    void setUp() {
        controller = new ConsultationController(consultationService);
        lenient().when(consultationService.bookingCounts()).thenReturn(Map.of(10L, 4L));
    }

    private ConsultationSlot slot(long id, Teacher teacher) {
        return ConsultationSlot.builder()
            .id(id).teacher(teacher)
            .date(LocalDate.of(2026, 9, 2))
            .startTime(LocalTime.of(14, 0))
            .endTime(LocalTime.of(15, 0))
            .build();
    }

    private Map<Teacher, List<ConsultationSlot>> grouped(Object... teacherThenSlots) {
        Map<Teacher, List<ConsultationSlot>> map = new LinkedHashMap<>();
        for (int i = 0; i < teacherThenSlots.length; i += 2) {
            @SuppressWarnings("unchecked")
            List<ConsultationSlot> slots = (List<ConsultationSlot>) teacherThenSlots[i + 1];
            map.put((Teacher) teacherThenSlots[i], slots);
        }
        return map;
    }

    @Test
    void carriesTheBookingCountOntoTheSlot() {
        when(consultationService.getAllGrouped())
            .thenReturn(grouped(chorbev, List.of(slot(10L, chorbev))));

        List<TeacherWithSlotsResponse> out = controller.getAll(null);

        assertThat(out).hasSize(1);
        assertThat(out.get(0).slots().get(0).enrolledCount()).isEqualTo(4);
    }

    @Test
    void aSlotNobodyBookedReportsZero() {
        when(consultationService.getAllGrouped())
            .thenReturn(grouped(chorbev, List.of(slot(77L, chorbev))));

        assertThat(controller.getAll(null).get(0).slots().get(0).enrolledCount()).isZero();
    }

    /** Counts are read once for the whole response, never once per slot. */
    @Test
    void readsBookingCountsOnce_andNeverPerSlot() {
        when(consultationService.getAllGrouped()).thenReturn(grouped(
            chorbev, List.of(slot(10L, chorbev), slot(11L, chorbev)),
            antovski, List.of(slot(12L, antovski))));

        controller.getAll(null);

        verify(consultationService, times(1)).bookingCounts();
        verify(consultationService, never()).countBookings(anyLong());
    }

    @Test
    void ordersProfessorsByName() {
        when(consultationService.getAllGrouped())
            .thenReturn(grouped(chorbev, List.of(), antovski, List.of()));

        assertThat(controller.getAll(null))
            .extracting(r -> r.teacher().cyrillicName())
            .containsExactly("Александар Антовски", "Иван Чорбев");
    }

    @Test
    void aSearchGroupsMatchingSlotsByTeacher_andIsOrderedToo() {
        when(consultationService.search("чорбев"))
            .thenReturn(List.of(slot(12L, antovski), slot(10L, chorbev)));

        List<TeacherWithSlotsResponse> out = controller.getAll("чорбев");

        assertThat(out).extracting(r -> r.teacher().cyrillicName())
            .containsExactly("Александар Антовски", "Иван Чорбев");
        verify(consultationService, never()).getAllGrouped();
        verify(consultationService, times(1)).bookingCounts();
    }

    @Test
    void aBlankSearchFallsBackToTheFullList() {
        when(consultationService.getAllGrouped()).thenReturn(new LinkedHashMap<>());
        controller.getAll("   ");
        verify(consultationService, times(1)).getAllGrouped();
    }
}
