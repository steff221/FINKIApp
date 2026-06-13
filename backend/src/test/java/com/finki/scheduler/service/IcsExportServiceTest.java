package com.finki.scheduler.service;

import com.finki.scheduler.domain.Classroom;
import com.finki.scheduler.domain.ConsultationSlot;
import com.finki.scheduler.domain.CustomScheduleEntry;
import com.finki.scheduler.domain.ScheduleSlot;
import com.finki.scheduler.domain.Subject;
import com.finki.scheduler.domain.Teacher;
import com.finki.scheduler.repository.ConsultationSlotRepository;
import com.finki.scheduler.repository.CustomScheduleEntryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class IcsExportServiceTest {

    private static final long USER_ID = 7L;

    @Mock private UserScheduleService userScheduleService;
    @Mock private ConsultationSlotRepository consultationSlotRepo;
    @Mock private CustomScheduleEntryRepository customEntryRepo;

    private IcsExportService service;

    @BeforeEach
    void setUp() {
        service = new IcsExportService(userScheduleService, consultationSlotRepo, customEntryRepo);
        // Default to empty so each test only stubs what it needs.
        lenient().when(userScheduleService.getSchedule(anyLong())).thenReturn(List.of());
        lenient().when(consultationSlotRepo.findByTeacherIdOrderByDateAscStartTimeAsc(anyLong())).thenReturn(List.of());
        lenient().when(customEntryRepo.findByUserIdOrderByDayOfWeekAscStartTimeAsc(anyLong())).thenReturn(List.of());
    }

    private ScheduleSlot classSlot(long id, String subject, String room, Teacher... teachers) {
        return ScheduleSlot.builder()
            .id(id)
            .subject(Subject.builder().baseName(subject).build())
            .classroom(Classroom.builder().name(room).build())
            .dayOfWeek(0) // Monday
            .startTime(LocalTime.of(8, 0))
            .endTime(LocalTime.of(9, 30))
            .teachers(Set.of(teachers))
            .build();
    }

    @Test
    void emptySchedule_producesValidEmptyCalendar() {
        String ics = service.export(USER_ID);

        assertThat(ics)
            .startsWith("BEGIN:VCALENDAR\r\n")
            .endsWith("END:VCALENDAR\r\n")
            .contains("VERSION:2.0\r\n")
            .doesNotContain("BEGIN:VEVENT");
    }

    @Test
    void everyLineIsCrlfTerminated() {
        when(userScheduleService.getSchedule(USER_ID))
            .thenReturn(List.of(classSlot(1, "Калкулус", "Б2.1")));

        String ics = service.export(USER_ID);

        // No bare LF: every \n must be preceded by \r.
        assertThat(ics.replace("\r\n", "")).doesNotContain("\n");
    }

    @Test
    void classSlot_emittedAsWeeklyEventWithStableUidAndDtstamp() {
        when(userScheduleService.getSchedule(USER_ID))
            .thenReturn(List.of(classSlot(42, "Калкулус", "Б2.1")));

        String ics = service.export(USER_ID);

        assertThat(ics)
            .contains("BEGIN:VEVENT\r\n")
            .contains("UID:slot-42@finki-scheduler\r\n")
            .contains("RRULE:FREQ=WEEKLY\r\n")
            .contains("SUMMARY:Калкулус\r\n")
            .contains("LOCATION:Б2.1\r\n")
            .containsPattern("DTSTAMP:\\d{8}T\\d{6}Z\\r\\n")
            .contains("DTSTART;TZID=Europe/Skopje:");
    }

    @Test
    void uidsAreStableAcrossRepeatedExports() {
        when(userScheduleService.getSchedule(USER_ID))
            .thenReturn(List.of(classSlot(42, "Калкулус", "Б2.1")));

        String first  = service.export(USER_ID);
        String second = service.export(USER_ID);

        // Same logical event → same UID, so re-import updates instead of duplicating.
        assertThat(first).contains("UID:slot-42@finki-scheduler");
        assertThat(second).contains("UID:slot-42@finki-scheduler");
    }

    @Test
    void specialCharactersInSummaryAreEscaped() {
        CustomScheduleEntry entry = CustomScheduleEntry.builder()
            .id(5L)
            .title("Project; review, part one")
            .professor("line1\nline2")
            .dayOfWeek(2)
            .startTime(LocalTime.of(10, 0))
            .endTime(LocalTime.of(11, 0))
            .build();
        when(customEntryRepo.findByUserIdOrderByDayOfWeekAscStartTimeAsc(USER_ID))
            .thenReturn(List.of(entry));

        String ics = service.export(USER_ID);

        assertThat(ics)
            .contains("UID:custom-5@finki-scheduler\r\n")
            .contains("SUMMARY:Project\\; review\\, part one\r\n")
            .contains("DESCRIPTION:line1\\nline2\r\n");
    }

    @Test
    void consultationSlot_emittedAsOneTimeEventWithCompositeUid() {
        Teacher teacher = Teacher.builder()
            .id(3L).cyrillicName("Игор Мишковски").consultationUsername("igor.mishkovski").build();
        when(userScheduleService.getSchedule(USER_ID))
            .thenReturn(List.of(classSlot(1, "ОБП", "Лаб", teacher)));

        ConsultationSlot cs = ConsultationSlot.builder()
            .id(9L).teacher(teacher)
            .date(LocalDate.of(2026, 6, 20))
            .startTime(LocalTime.of(12, 0)).endTime(LocalTime.of(13, 0))
            .room("214").build();
        when(consultationSlotRepo.findByTeacherIdOrderByDateAscStartTimeAsc(3L))
            .thenReturn(List.of(cs));

        String ics = service.export(USER_ID);

        assertThat(ics)
            .contains("UID:consult-9-3@finki-scheduler\r\n")
            .contains("SUMMARY:Consultations: Игор Мишковски\r\n")
            .contains("LOCATION:214\r\n");

        // The consultation VEVENT itself is one-time (no RRULE), even though the
        // class slot carrying the teacher is weekly.
        String consultBlock = vEventBlockContaining(ics, "consult-9-3");
        assertThat(consultBlock).doesNotContain("RRULE");
    }

    /** Returns the BEGIN:VEVENT…END:VEVENT block whose body contains the given marker. */
    private static String vEventBlockContaining(String ics, String marker) {
        for (String block : ics.split("BEGIN:VEVENT")) {
            if (block.contains(marker)) return block.substring(0, block.indexOf("END:VEVENT"));
        }
        throw new AssertionError("No VEVENT block containing: " + marker);
    }
}
