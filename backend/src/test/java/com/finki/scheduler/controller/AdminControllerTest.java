package com.finki.scheduler.controller;

import com.finki.scheduler.repository.TeacherRepository;
import com.finki.scheduler.service.ConsultationImportService;
import com.finki.scheduler.service.ExamService;
import com.finki.scheduler.service.ingestion.ScheduledIngestionJob;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AdminControllerTest {

    @Mock private ScheduledIngestionJob ingestionJob;
    @Mock private TeacherRepository teacherRepo;
    @Mock private ExamService examService;
    @Mock private ConsultationImportService consultationImportService;

    private AdminController controller;

    @BeforeEach
    void setUp() {
        controller = new AdminController(ingestionJob, teacherRepo, examService, consultationImportService);
    }

    /**
     * The whole point of routing imports through ResponseStatusException: the
     * global handler would otherwise answer "Malformed or invalid request" and
     * leave the admin guessing which line of the file is wrong.
     */
    @Test
    void aBadExamRowIsReportedWithItsDetail() {
        when(examService.importCsv(anyString(), anyString()))
            .thenThrow(new IllegalArgumentException("Could not parse row 14: missing date"));

        assertThatThrownBy(() -> controller.importExams("Јунска", "subject,date\nx,y\n"))
            .isInstanceOf(ResponseStatusException.class)
            .satisfies(ex -> {
                ResponseStatusException rse = (ResponseStatusException) ex;
                assertThat(rse.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
                assertThat(rse.getReason()).contains("row 14").contains("missing date");
            });
    }

    @Test
    void aBadConsultationRowIsReportedWithItsDetail() {
        when(consultationImportService.importCsv(anyString()))
            .thenThrow(new IllegalArgumentException("Unrecognised professor(s): Тест Професор"));

        assertThatThrownBy(() -> controller.importConsultations("professor,date\nx,y\n"))
            .isInstanceOf(ResponseStatusException.class)
            .satisfies(ex -> assertThat(((ResponseStatusException) ex).getReason())
                .contains("Unrecognised professor"));
    }

    @Test
    void anOversizedExamCsvIsRejectedBeforeParsing() {
        String huge = "x".repeat(2_000_001);
        assertThatThrownBy(() -> controller.importExams("Јунска", huge))
            .isInstanceOf(ResponseStatusException.class)
            .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode())
                .isEqualTo(HttpStatus.PAYLOAD_TOO_LARGE));
    }

    @Test
    void anOversizedConsultationCsvIsRejectedBeforeParsing() {
        String huge = "x".repeat(2_000_001);
        assertThatThrownBy(() -> controller.importConsultations(huge))
            .isInstanceOf(ResponseStatusException.class)
            .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode())
                .isEqualTo(HttpStatus.PAYLOAD_TOO_LARGE));
    }

    @Test
    void aGoodImportReportsWhatItStored() {
        when(consultationImportService.importCsv(anyString()))
            .thenReturn(new ConsultationImportService.ImportResult(2, 5, 1));

        var body = controller.importConsultations("professor,date\nx,y\n").getBody();

        assertThat(body).containsEntry("status", "ok")
            .containsEntry("professors", 2)
            .containsEntry("slotsStored", 5)
            .containsEntry("slotsRemoved", 1);
    }
}
