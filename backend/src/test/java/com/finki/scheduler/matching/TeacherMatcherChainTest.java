package com.finki.scheduler.matching;

import com.finki.scheduler.domain.Teacher;
import com.finki.scheduler.domain.TeacherMatchOverride;
import com.finki.scheduler.repository.TeacherMatchOverrideRepository;
import com.finki.scheduler.repository.TeacherRepository;
import com.finki.scheduler.service.matching.NameNormalizer;
import com.finki.scheduler.service.matching.TeacherMatcherService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;


@ExtendWith(MockitoExtension.class)
class TeacherMatcherChainTest {

    @Mock private TeacherRepository teacherRepo;
    @Mock private TeacherMatchOverrideRepository overrideRepo;

    private TeacherMatcherService matcher;

    @BeforeEach
    void setUp() {
        matcher = new TeacherMatcherService(teacherRepo, overrideRepo, new NameNormalizer());
        // Saves echo the argument back so assertions can inspect the merged row.
        lenient().when(teacherRepo.save(any(Teacher.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    private Teacher edupage(long id, String name) {
        return Teacher.builder().id(id).edupageId("EP" + id).cyrillicName(name).build();
    }

    private Teacher consultation(long id, String username, String displayName) {
        return Teacher.builder().id(id).consultationUsername(username).cyrillicName(displayName).build();
    }

    @Test
    void manualOverride_takesPrecedence_overBetterFuzzyMatch() {
        Teacher ep = edupage(1, "Игор Мишковски");
        Teacher overrideTarget = consultation(2, "i.mishkovski", "Игор М.");
        Teacher fuzzyBetter    = consultation(3, "igor.mishkovski", "Игор Мишковски");

        when(overrideRepo.findByEdupageId("EP1"))
            .thenReturn(Optional.of(override("EP1", "i.mishkovski")));
        when(teacherRepo.findByConsultationUsername("i.mishkovski"))
            .thenReturn(Optional.of(overrideTarget));

        matcher.tryMatch(ep, List.of(overrideTarget, fuzzyBetter));

        // The override target wins even though fuzzyBetter would score higher.
        assertThat(ep.getConsultationUsername()).isEqualTo("i.mishkovski");
        assertThat(ep.isManualOverride()).isTrue();
        assertThat(ep.getMatchConfidence()).isEqualByComparingTo(BigDecimal.ONE);
        verify(teacherRepo).delete(overrideTarget);
        verify(teacherRepo, never()).delete(fuzzyBetter);
    }

    @Test
    void exactMatch_mergesWithFullConfidence() {
        Teacher ep = edupage(1, "Игор Мишковски");
        Teacher exact = consultation(2, "igor.mishkovski", "Игор Мишковски");

        when(overrideRepo.findByEdupageId("EP1")).thenReturn(Optional.empty());

        matcher.tryMatch(ep, List.of(exact));

        assertThat(ep.getConsultationUsername()).isEqualTo("igor.mishkovski");
        assertThat(ep.isManualOverride()).isFalse();
        assertThat(ep.getMatchConfidence()).isEqualByComparingTo(new BigDecimal("1.000"));
        verify(teacherRepo).delete(exact);
    }

    @Test
    void lowConfidenceMatch_mergesButFlaggedNotManual() {
        Teacher ep = edupage(1, "Зоран Петровски");
        // A heavily truncated username ("zoran pe") still shares the given name and a
        // surname prefix, landing in the low-confidence band rather than a clean match.
        Teacher weak = consultation(2, "zoran.pe", "Зоран Пе");

        when(overrideRepo.findByEdupageId("EP1")).thenReturn(Optional.empty());

        matcher.tryMatch(ep, List.of(weak));

        assertThat(ep.getConsultationUsername()).isEqualTo("zoran.pe");
        assertThat(ep.isManualOverride()).isFalse();
        assertThat(ep.getMatchConfidence()).isBetween(new BigDecimal("0.600"), new BigDecimal("0.849"));
    }

    @Test
    void noCandidateAboveThreshold_leavesTeacherUnmatched() {
        Teacher ep = edupage(1, "Зоран Петров");
        Teacher unrelated = consultation(2, "ana.todorovska", "Ана Тодоровска");

        when(overrideRepo.findByEdupageId("EP1")).thenReturn(Optional.empty());

        matcher.tryMatch(ep, List.of(unrelated));

        assertThat(ep.getConsultationUsername()).isNull();
        verify(teacherRepo, never()).save(any(Teacher.class));
        verify(teacherRepo, never()).delete(any(Teacher.class));
    }

    @Test
    void picksHighestScoringCandidate_amongSeveral() {
        Teacher ep = edupage(1, "Александар Тенев");
        Teacher wrong = consultation(2, "ana.todorovska", "Ана Тодоровска");
        Teacher best  = consultation(3, "aleksandar.tenev", "Александар Тенев");

        when(overrideRepo.findByEdupageId("EP1")).thenReturn(Optional.empty());

        matcher.tryMatch(ep, List.of(wrong, best));

        assertThat(ep.getConsultationUsername()).isEqualTo("aleksandar.tenev");
        ArgumentCaptor<Teacher> saved = ArgumentCaptor.forClass(Teacher.class);
        verify(teacherRepo).save(saved.capture());
        assertThat(saved.getValue().getConsultationUsername()).isEqualTo("aleksandar.tenev");
        verify(teacherRepo).delete(best);
        verify(teacherRepo, never()).delete(wrong);
    }

    private TeacherMatchOverride override(String edupageId, String username) {
        TeacherMatchOverride ov = new TeacherMatchOverride();
        ov.setEdupageId(edupageId);
        ov.setConsultationUsername(username);
        return ov;
    }
}
