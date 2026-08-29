package com.finki.scheduler.service;

import com.finki.scheduler.domain.ConsultationSlot;
import com.finki.scheduler.domain.Teacher;
import com.finki.scheduler.repository.ConsultationBookingRepository;
import com.finki.scheduler.repository.ConsultationSlotRepository;
import com.finki.scheduler.repository.TeacherRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalTime;
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
class ConsultationServiceTest {

    @Mock private TeacherRepository teacherRepo;
    @Mock private ConsultationSlotRepository slotRepo;
    @Mock private ConsultationBookingRepository bookingRepo;

    private ConsultationService service;

    private final Teacher withSlots = Teacher.builder().id(1L).cyrillicName("Иван Чорбев").build();
    private final Teacher withoutSlots = Teacher.builder().id(2L).cyrillicName("Јана Кузманова").build();

    @BeforeEach
    void setUp() {
        service = new ConsultationService(teacherRepo, slotRepo, bookingRepo);
        lenient().when(teacherRepo.findAll()).thenReturn(List.of(withSlots, withoutSlots));
        lenient().when(slotRepo.findAllWithTeacher()).thenReturn(List.of(slot(10L, withSlots)));
    }

    private ConsultationSlot slot(long id, Teacher teacher) {
        return ConsultationSlot.builder()
            .id(id).teacher(teacher)
            .date(LocalDate.of(2026, 9, 2))
            .startTime(LocalTime.of(14, 0))
            .endTime(LocalTime.of(15, 0))
            .build();
    }

    @Test
    void groupsSlotsUnderTheirTeacher() {
        Map<Teacher, List<ConsultationSlot>> grouped = service.getAllGrouped();
        assertThat(grouped.get(withSlots)).extracting(ConsultationSlot::getId).containsExactly(10L);
    }

    /** A professor who has published nothing still belongs on the list. */
    @Test
    void keepsTeachersThatHaveNoSlots() {
        assertThat(service.getAllGrouped().get(withoutSlots)).isEmpty();
    }

    /**
     * The point of the change: the roster and the slots, and nothing per teacher.
     * A per-teacher lookup creeping back in is what made this screen slow.
     */
    @Test
    void readsTheWholeListInTwoQueries() {
        service.getAllGrouped();

        verify(teacherRepo, times(1)).findAll();
        verify(slotRepo, times(1)).findAllWithTeacher();
        verify(slotRepo, never()).findByTeacherIdOrderByDateAscStartTimeAsc(anyLong());
    }

    @Test
    void mapsBookingCountsBySlotId() {
        when(bookingRepo.countBookingsPerSlot())
            .thenReturn(List.of(new Object[] {10L, 3L}, new Object[] {11L, 1L}));

        Map<Long, Long> counts = service.bookingCounts();

        assertThat(counts).containsEntry(10L, 3L).containsEntry(11L, 1L);
        verify(bookingRepo, times(1)).countBookingsPerSlot();
        verify(bookingRepo, never()).countBySlotId(anyLong());
    }

    /** Hibernate hands back whatever numeric type the driver chose; both must map. */
    @Test
    void toleratesIntegerCountsFromTheDriver() {
        when(bookingRepo.countBookingsPerSlot())
            .thenReturn(List.<Object[]>of(new Object[] {Integer.valueOf(10), Integer.valueOf(2)}));
        assertThat(service.bookingCounts()).containsEntry(10L, 2L);
    }

    @Test
    void anUnbookedSlotCountsZeroRatherThanFailing() {
        Map<Long, Long> counts = Map.of(10L, 3L);
        assertThat(ConsultationService.bookingCountOf(counts, 10L)).isEqualTo(3L);
        assertThat(ConsultationService.bookingCountOf(counts, 999L)).isZero();
    }
}
