package com.finki.scheduler.service;

import com.finki.scheduler.domain.Exam;
import com.finki.scheduler.repository.ExamRepository;
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
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

/**
 * The exam CSV importer had no tests, and it is the path a whole exam session
 * arrives through. These pin the parsing down before it is refactored.
 */
@ExtendWith(MockitoExtension.class)
class ExamServiceTest {

    private static final String SESSION = "Јунска сесија 2025/26";
    private static final String HEADER = "subject,date,startTime,endTime,rooms,note\n";

    @Mock private ExamRepository examRepo;

    private ExamService service;

    @BeforeEach
    void setUp() {
        service = new ExamService(examRepo);
    }

    private List<Exam> imported(String csv) {
        service.importCsv(SESSION, csv);
        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<Exam>> saved = ArgumentCaptor.forClass(List.class);
        verify(examRepo).saveAll(saved.capture());
        return saved.getValue();
    }

    @Test
    void readsEveryColumnOfARow() {
        Exam exam = imported(HEADER
            + "Веб програмирање,2026-09-02,17:00,21:00,лаб. 138,Носете индекс\n").get(0);

        assertThat(exam.getSession()).isEqualTo(SESSION);
        assertThat(exam.getSubjectName()).isEqualTo("Веб програмирање");
        assertThat(exam.getDate()).isEqualTo(LocalDate.of(2026, 9, 2));
        assertThat(exam.getStartTime()).isEqualTo(LocalTime.of(17, 0));
        assertThat(exam.getEndTime()).isEqualTo(LocalTime.of(21, 0));
        assertThat(exam.getRooms()).isEqualTo("лаб. 138");
        assertThat(exam.getNote()).isEqualTo("Носете индекс");
    }

    @Test
    void replacesWhateverTheSessionAlreadyHeld() {
        service.importCsv(SESSION, HEADER + "Веб,2026-09-02,17:00,21:00,,\n");
        verify(examRepo).deleteBySession(SESSION);
    }

    @Test
    void acceptsTheThreeDateFormsTheFacultyPublishes() {
        List<Exam> exams = imported(HEADER
            + "A,2026-09-02,09:00,11:00,,\n"
            + "B,02.09.2026,09:00,11:00,,\n"
            + "C,02/09/2026,09:00,11:00,,\n");

        assertThat(exams).extracting(Exam::getDate)
            .containsOnly(LocalDate.of(2026, 9, 2));
    }

    @Test
    void readsATwoDigitYearAsThisCentury() {
        assertThat(imported(HEADER + "A,02.09.26,09:00,11:00,,\n").get(0).getDate())
            .isEqualTo(LocalDate.of(2026, 9, 2));
    }

    @Test
    void acceptsSecondsOnATime() {
        Exam exam = imported(HEADER + "A,2026-09-02,09:00:00,11:30:00,,\n").get(0);
        assertThat(exam.getStartTime()).isEqualTo(LocalTime.of(9, 0));
        assertThat(exam.getEndTime()).isEqualTo(LocalTime.of(11, 30));
    }

    @Test
    void leavesAMissingTimeUnset() {
        Exam exam = imported(HEADER + "A,2026-09-02,,,,\n").get(0);
        assertThat(exam.getStartTime()).isNull();
        assertThat(exam.getEndTime()).isNull();
    }

    @Test
    void takesSemicolonsWhenTheHeaderUsesThem() {
        List<Exam> exams = imported("subject;date;startTime;endTime;rooms;note\n"
            + "Веб програмирање;2026-09-02;17:00;21:00;лаб. 138;\n");
        assertThat(exams.get(0).getRooms()).isEqualTo("лаб. 138");
    }

    /** Room lists are the reason quoting exists here: "лаб. 2, лаб. 3" is one field. */
    @Test
    void keepsAQuotedFieldWhole() {
        Exam exam = imported(HEADER + "A,2026-09-02,09:00,11:00,\"лаб. 2, лаб. 3\",\n").get(0);
        assertThat(exam.getRooms()).isEqualTo("лаб. 2, лаб. 3");
    }

    @Test
    void unwrapsADoubledQuoteInsideAField() {
        Exam exam = imported(HEADER + "A,2026-09-02,09:00,11:00,,\"каже \"\"да\"\"\"\n").get(0);
        assertThat(exam.getNote()).isEqualTo("каже \"да\"");
    }

    @Test
    void survivesAByteOrderMarkFromExcel() {
        List<Exam> exams = imported("﻿" + HEADER + "A,2026-09-02,09:00,11:00,,\n");
        assertThat(exams).hasSize(1);
    }

    @Test
    void skipsBlankAndSpacerRows() {
        List<Exam> exams = imported(HEADER
            + "A,2026-09-02,09:00,11:00,,\n"
            + "\n"
            + ",,,,,\n"
            + "B,2026-09-03,09:00,11:00,,\n");
        assertThat(exams).extracting(Exam::getSubjectName).containsExactly("A", "B");
    }

    @Test
    void anEmptyFieldBecomesNullRatherThanBlank() {
        Exam exam = imported(HEADER + "A,2026-09-02,09:00,11:00,,\n").get(0);
        assertThat(exam.getRooms()).isNull();
        assertThat(exam.getNote()).isNull();
    }

    @Test
    void aBadRowIsReportedWithItsLineNumber() {
        assertThatThrownBy(() -> service.importCsv(SESSION, HEADER
            + "A,2026-09-02,09:00,11:00,,\n"
            + "B,not-a-date,09:00,11:00,,\n"))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("row 3");
    }

    @Test
    void nothingIsStoredWhenARowFails() {
        assertThatThrownBy(() -> service.importCsv(SESSION, HEADER + "A,nope,09:00,11:00,,\n"))
            .isInstanceOf(IllegalArgumentException.class);
        verify(examRepo, never()).saveAll(org.mockito.ArgumentMatchers.any());
        verify(examRepo, never()).deleteBySession(anyString());
    }

    @Test
    void aSessionIsRequired() {
        assertThatThrownBy(() -> service.importCsv("  ", HEADER + "A,2026-09-02,09:00,11:00,,\n"))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("session");
    }

    @Test
    void anEmptyBodyIsRejected() {
        assertThatThrownBy(() -> service.importCsv(SESSION, "   "))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("empty");
    }

    @Test
    void aHeaderWithNoRowsIsRejected() {
        assertThatThrownBy(() -> service.importCsv(SESSION, HEADER))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("No exam rows");
    }
}
