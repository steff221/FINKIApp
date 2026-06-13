package com.finki.scheduler.service;

import com.finki.scheduler.domain.ConsultationSlot;
import com.finki.scheduler.domain.CustomScheduleEntry;
import com.finki.scheduler.domain.ScheduleSlot;
import com.finki.scheduler.domain.Teacher;
import com.finki.scheduler.repository.ConsultationSlotRepository;
import com.finki.scheduler.repository.CustomScheduleEntryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.*;
import java.time.format.DateTimeFormatter;
import java.time.temporal.TemporalAdjusters;
import java.util.List;

/**
 * Generates a .ics file for a user's personal schedule.
 *
 * Class slots are emitted as WEEKLY recurring events anchored to the Monday of the
 * current week (so the first occurrence is the next occurrence of that weekday).
 * Teacher consultation slots are emitted as one-time VEVENT entries.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class IcsExportService {

    private static final DateTimeFormatter ICS_DT = DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss");
    private static final DateTimeFormatter ICS_UTC = DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss'Z'");
    private static final ZoneId SKOPJE = ZoneId.of("Europe/Skopje");

    /** Stable DTSTAMP for the whole file — the moment the calendar was generated, in UTC. */
    private final String dtStamp = ICS_UTC.format(ZonedDateTime.now(ZoneOffset.UTC));

    private final UserScheduleService userScheduleService;
    private final ConsultationSlotRepository consultationSlotRepo;
    private final CustomScheduleEntryRepository customEntryRepo;

    public String export(Long userId) {
        List<ScheduleSlot> slots = userScheduleService.getSchedule(userId);
        StringBuilder sb = new StringBuilder();

        sb.append("BEGIN:VCALENDAR\r\n");
        sb.append("VERSION:2.0\r\n");
        sb.append("PRODID:-//FINKIApp//Schedule//EN\r\n");
        sb.append("CALSCALE:GREGORIAN\r\n");
        sb.append("METHOD:PUBLISH\r\n");

        for (ScheduleSlot slot : slots) {
            appendClassSlot(sb, slot);
            // Inline: append each teacher's upcoming consultation slots
            for (Teacher teacher : slot.getTeachers()) {
                if (teacher.getConsultationUsername() != null) {
                    consultationSlotRepo
                        .findByTeacherIdOrderByDateAscStartTimeAsc(teacher.getId())
                        .forEach(cs -> appendConsultationSlot(sb, cs, teacher));
                }
            }
        }

        // The user's custom weekly calendar (My Schedule), as weekly recurring events
        for (CustomScheduleEntry entry : customEntryRepo.findByUserIdOrderByDayOfWeekAscStartTimeAsc(userId)) {
            appendCustomEntry(sb, entry);
        }

        sb.append("END:VCALENDAR\r\n");
        return sb.toString();
    }

    private void appendCustomEntry(StringBuilder sb, CustomScheduleEntry entry) {
        LocalDate today = LocalDate.now(SKOPJE);
        DayOfWeek dow = DayOfWeek.of(entry.getDayOfWeek() + 1); // 0=Mon → 1
        LocalDate firstDate = today.with(TemporalAdjusters.nextOrSame(dow));

        ZonedDateTime dtStart = ZonedDateTime.of(firstDate, entry.getStartTime(), SKOPJE);
        ZonedDateTime dtEnd   = ZonedDateTime.of(firstDate, entry.getEndTime(),   SKOPJE);

        sb.append("BEGIN:VEVENT\r\n");
        sb.append("UID:custom-").append(entry.getId()).append("@finki-scheduler\r\n");
        sb.append("DTSTAMP:").append(dtStamp).append("\r\n");
        sb.append("DTSTART;TZID=Europe/Skopje:").append(dtStart.format(ICS_DT)).append("\r\n");
        sb.append("DTEND;TZID=Europe/Skopje:").append(dtEnd.format(ICS_DT)).append("\r\n");
        sb.append("RRULE:FREQ=WEEKLY\r\n");
        sb.append("SUMMARY:").append(escape(entry.getTitle())).append("\r\n");
        if (entry.getRoom() != null && !entry.getRoom().isBlank())
            sb.append("LOCATION:").append(escape(entry.getRoom())).append("\r\n");
        if (entry.getProfessor() != null && !entry.getProfessor().isBlank())
            sb.append("DESCRIPTION:").append(escape(entry.getProfessor())).append("\r\n");
        sb.append("END:VEVENT\r\n");
    }

    private void appendClassSlot(StringBuilder sb, ScheduleSlot slot) {
        // Anchor: next occurrence of this day-of-week from today
        LocalDate today = LocalDate.now(SKOPJE);
        DayOfWeek dow = DayOfWeek.of(slot.getDayOfWeek() + 1); // 0=Mon → 1
        LocalDate firstDate = today.with(TemporalAdjusters.nextOrSame(dow));

        ZonedDateTime dtStart = ZonedDateTime.of(firstDate, slot.getStartTime(), SKOPJE);
        ZonedDateTime dtEnd   = ZonedDateTime.of(firstDate, slot.getEndTime(),   SKOPJE);

        String teacherNames = slot.getTeachers().stream()
            .map(Teacher::getCyrillicName).filter(n -> n != null && !n.isBlank())
            .reduce((a, b) -> a + ", " + b).orElse("");
        String location = slot.getClassroom() != null ? slot.getClassroom().getName() : "";
        String summary  = slot.getSubject().getBaseName();

        sb.append("BEGIN:VEVENT\r\n");
        sb.append("UID:slot-").append(slot.getId()).append("@finki-scheduler\r\n");
        sb.append("DTSTAMP:").append(dtStamp).append("\r\n");
        sb.append("DTSTART;TZID=Europe/Skopje:").append(dtStart.format(ICS_DT)).append("\r\n");
        sb.append("DTEND;TZID=Europe/Skopje:").append(dtEnd.format(ICS_DT)).append("\r\n");
        sb.append("RRULE:FREQ=WEEKLY\r\n");
        sb.append("SUMMARY:").append(escape(summary)).append("\r\n");
        if (!location.isBlank()) sb.append("LOCATION:").append(escape(location)).append("\r\n");
        if (!teacherNames.isBlank()) sb.append("DESCRIPTION:").append(escape(teacherNames)).append("\r\n");
        sb.append("END:VEVENT\r\n");
    }

    private void appendConsultationSlot(StringBuilder sb, ConsultationSlot cs, Teacher teacher) {
        ZonedDateTime dtStart = ZonedDateTime.of(cs.getDate(), cs.getStartTime(), SKOPJE);
        ZonedDateTime dtEnd   = ZonedDateTime.of(cs.getDate(), cs.getEndTime(),   SKOPJE);

        String summary = "Consultations: " + (teacher.getCyrillicName() != null
            ? teacher.getCyrillicName() : teacher.getConsultationUsername());

        sb.append("BEGIN:VEVENT\r\n");
        sb.append("UID:consult-").append(cs.getId()).append('-').append(teacher.getId()).append("@finki-scheduler\r\n");
        sb.append("DTSTAMP:").append(dtStamp).append("\r\n");
        sb.append("DTSTART;TZID=Europe/Skopje:").append(dtStart.format(ICS_DT)).append("\r\n");
        sb.append("DTEND;TZID=Europe/Skopje:").append(dtEnd.format(ICS_DT)).append("\r\n");
        sb.append("SUMMARY:").append(escape(summary)).append("\r\n");
        if (cs.getRoom() != null && !cs.getRoom().isBlank())
            sb.append("LOCATION:").append(escape(cs.getRoom())).append("\r\n");
        if (cs.getInstructions() != null && !cs.getInstructions().isBlank())
            sb.append("DESCRIPTION:").append(escape(cs.getInstructions())).append("\r\n");
        sb.append("END:VEVENT\r\n");
    }

    private String escape(String s) {
        return s.replace("\\", "\\\\")
                .replace(";", "\\;")
                .replace(",", "\\,")
                .replace("\r\n", "\\n")
                .replace("\r", "\\n")
                .replace("\n", "\\n");
    }
}
