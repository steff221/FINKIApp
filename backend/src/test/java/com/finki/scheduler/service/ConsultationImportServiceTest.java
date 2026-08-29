package com.finki.scheduler.service;

import com.finki.scheduler.domain.ConsultationSlot;
import com.finki.scheduler.domain.Teacher;
import com.finki.scheduler.repository.ConsultationSlotRepository;
import com.finki.scheduler.repository.TeacherRepository;
import com.finki.scheduler.service.matching.NameNormalizer;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ConsultationImportServiceTest {

    private static final String HEADER = "professor,date,startTime,endTime,room,instructions\n";

    @Mock private TeacherRepository teacherRepo;
    @Mock private ConsultationSlotRepository slotRepo;

    private ConsultationImportService service;

    private final Teacher chorbev = Teacher.builder()
        .id(1L).edupageId("EP1")
        .cyrillicName("Иван Чорбев")
        .canonicalName("ivan chorbev")
        .consultationUsername("ivan.chorbev")
        .build();

    @BeforeEach
    void setUp() {
        service = new ConsultationImportService(teacherRepo, slotRepo, new NameNormalizer());
        lenient().when(teacherRepo.findAll()).thenReturn(List.of(chorbev));
        lenient().when(slotRepo.findByTeacherIdOrderByDateAscStartTimeAsc(anyLong())).thenReturn(List.of());
        lenient().when(slotRepo.save(any(ConsultationSlot.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    private String row(String professor) {
        return HEADER + professor + ",2026-09-02,14:00,15:30,лаб. 138,Однесете индекс\n";
    }

    @Test
    void resolvesProfessorByCyrillicName() {
        var result = service.importCsv(row("Иван Чорбев"));
        assertThat(result.professors()).isEqualTo(1);
        assertThat(result.slotsStored()).isEqualTo(1);
    }

    @Test
    void resolvesProfessorByConsultationUsername() {
        assertThat(service.importCsv(row("ivan.chorbev")).slotsStored()).isEqualTo(1);
    }

    @Test
    void resolvesProfessorByLatinTransliteration() {
        assertThat(service.importCsv(row("Ivan Chorbev")).slotsStored()).isEqualTo(1);
    }

    @Test
    void storesEveryColumn() {
        service.importCsv(row("Иван Чорбев"));

        ArgumentCaptor<ConsultationSlot> saved = ArgumentCaptor.forClass(ConsultationSlot.class);
        verify(slotRepo).save(saved.capture());
        ConsultationSlot slot = saved.getValue();

        assertThat(slot.getTeacher()).isEqualTo(chorbev);
        assertThat(slot.getDate()).isEqualTo(LocalDate.of(2026, 9, 2));
        assertThat(slot.getStartTime()).isEqualTo(LocalTime.of(14, 0));
        assertThat(slot.getEndTime()).isEqualTo(LocalTime.of(15, 30));
        assertThat(slot.getRoom()).isEqualTo("лаб. 138");
        assertThat(slot.getInstructions()).isEqualTo("Однесете индекс");
    }

    /**
     * The whole reason this service reconciles instead of deleting: a slot that
     * survives an import keeps its id, so the bookings hanging off it survive too.
     */
    @Test
    void anUnchangedSlotKeepsItsId_soItsBookingsSurvive() {
        ConsultationSlot booked = ConsultationSlot.builder()
            .id(99L).teacher(chorbev)
            .date(LocalDate.of(2026, 9, 2))
            .startTime(LocalTime.of(14, 0))
            .endTime(LocalTime.of(15, 0))
            .build();
        when(slotRepo.findByTeacherIdOrderByDateAscStartTimeAsc(1L)).thenReturn(List.of(booked));

        service.importCsv(row("Иван Чорбев"));

        ArgumentCaptor<ConsultationSlot> saved = ArgumentCaptor.forClass(ConsultationSlot.class);
        verify(slotRepo).save(saved.capture());
        assertThat(saved.getValue().getId()).isEqualTo(99L);
        // and the changed field was carried over
        assertThat(saved.getValue().getEndTime()).isEqualTo(LocalTime.of(15, 30));
    }

    @Test
    void aSlotMissingFromTheFileIsWithdrawn() {
        ConsultationSlot stale = ConsultationSlot.builder()
            .id(7L).teacher(chorbev)
            .date(LocalDate.of(2026, 9, 1))
            .startTime(LocalTime.of(9, 0))
            .endTime(LocalTime.of(10, 0))
            .build();
        when(slotRepo.findByTeacherIdOrderByDateAscStartTimeAsc(1L)).thenReturn(List.of(stale));

        var result = service.importCsv(row("Иван Чорбев"));

        assertThat(result.slotsRemoved()).isEqualTo(1);
        ArgumentCaptor<List<ConsultationSlot>> deleted = ArgumentCaptor.forClass(List.class);
        verify(slotRepo).deleteAll(deleted.capture());
        assertThat(deleted.getValue()).extracting(ConsultationSlot::getId).containsExactly(7L);
    }

    @Test
    void anUnknownProfessorFailsTheWholeImport_andIsNamed() {
        assertThatThrownBy(() -> service.importCsv(row("Непостоечки Професор")))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("Непостоечки Професор");
        verify(slotRepo, org.mockito.Mockito.never()).save(any());
    }

    @Test
    void anAmbiguousNameIsRejectedRatherThanGuessed() {
        Teacher twin = Teacher.builder()
            .id(2L).edupageId("EP2").cyrillicName("Иван Чорбев").canonicalName("ivan chorbev").build();
        when(teacherRepo.findAll()).thenReturn(List.of(chorbev, twin));

        assertThatThrownBy(() -> service.importCsv(row("Иван Чорбев")))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("Unrecognised professor");
    }

    @Test
    void aMalformedRowNamesItsLineNumber() {
        String csv = HEADER + "Иван Чорбев,not-a-date,14:00,15:30,,\n";
        assertThatThrownBy(() -> service.importCsv(csv))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("row 2");
    }

    @Test
    void anEndTimeBeforeTheStartIsRejected() {
        String csv = HEADER + "Иван Чорбев,2026-09-02,15:30,14:00,,\n";
        assertThatThrownBy(() -> service.importCsv(csv))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("end time is not after start time");
    }

    @Test
    void acceptsDottedDatesAndSemicolonDelimiters() {
        String csv = "professor;date;startTime;endTime;room;instructions\n"
            + "Иван Чорбев;02.09.2026;14:00;15:30;лаб. 138;\n";
        assertThat(service.importCsv(csv).slotsStored()).isEqualTo(1);
    }

    @Test
    void anEmptyBodyIsRejected() {
        assertThatThrownBy(() -> service.importCsv("   "))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("empty");
    }

    @Test
    void aHeaderWithNoRowsIsRejected() {
        assertThatThrownBy(() -> service.importCsv(HEADER))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("No consultation rows");
    }
}
