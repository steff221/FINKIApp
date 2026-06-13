package com.finki.scheduler.service.matching;

import com.finki.scheduler.domain.Teacher;
import com.finki.scheduler.repository.TeacherMatchOverrideRepository;
import com.finki.scheduler.repository.TeacherRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Arrays;
import java.util.List;
import java.util.TreeSet;

/**
 * Matches EduPage teachers (Cyrillic names) to consultation usernames (Latin).
 *
 * Priority:
 *   1. Manual override in teacher_match_overrides table.
 *   2. Exact match after normalisation.
 *   3. Best fuzzy match (Levenshtein similarity) above HIGH_CONFIDENCE threshold.
 *   4. Best fuzzy match above LOW_CONFIDENCE threshold — stored but flagged.
 *   5. No match — teacher left with null consultation_username.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TeacherMatcherService {

    private static final double HIGH_CONFIDENCE = 0.85;
    private static final double LOW_CONFIDENCE  = 0.60;

    private final TeacherRepository teacherRepo;
    private final TeacherMatchOverrideRepository overrideRepo;
    private final NameNormalizer normalizer;

    /** A consultation teacher with its name fields normalised once, up front. */
    private record Candidate(Teacher teacher, String usernameNorm, String displayNorm) {}

    @Transactional
    public void matchAll() {
        List<Teacher> edupageTeachers = teacherRepo.findUnmatchedEdupageTeachers();
        // Only consultation-only teachers (no edupageId) are safe to delete during merge.
        // Already-merged teachers have schedule_slot_teachers FK references and cannot be deleted.
        List<Teacher> consultationTeachers = teacherRepo.findAll()
            .stream()
            .filter(t -> t.getConsultationUsername() != null && t.getEdupageId() == null)
            .toList();

        log.info("Matching {} EduPage teachers against {} consultation profiles",
            edupageTeachers.size(), consultationTeachers.size());

        for (Teacher ep : edupageTeachers) {
            tryMatch(ep, consultationTeachers);
        }
    }

    @Transactional
    public void tryMatch(Teacher edupageTeacher, List<Teacher> consultationTeachers) {
        // 1. Manual override takes absolute precedence
        overrideRepo.findByEdupageId(edupageTeacher.getEdupageId()).ifPresent(ov ->
            teacherRepo.findByConsultationUsername(ov.getConsultationUsername()).ifPresent(ct -> {
                merge(edupageTeacher, ct, BigDecimal.ONE, true);
                log.info("Manual override: {} → {}", edupageTeacher.getCyrillicName(), ov.getConsultationUsername());
            }));
        if (edupageTeacher.getConsultationUsername() != null) return;

        // Normalise each candidate's name fields once instead of once per EduPage teacher.
        List<Candidate> candidates = consultationTeachers.stream()
            .map(ct -> new Candidate(ct,
                normalizer.normalize(ct.getConsultationUsername()),
                normalizer.normalize(ct.getCyrillicName())))
            .toList();

        String epNorm = normalizer.normalize(edupageTeacher.getCyrillicName());

        Teacher bestCandidate = null;
        double bestScore = 0.0;

        for (Candidate c : candidates) {
            // Match against both the username and the scraped display name
            double scoreUsername = tokenSetSimilarity(epNorm, c.usernameNorm());
            double scoreDisplay  = tokenSetSimilarity(epNorm, c.displayNorm());
            double score = Math.max(scoreUsername, scoreDisplay);

            if (score > bestScore) {
                bestScore = score;
                bestCandidate = c.teacher();
            }
        }

        if (bestCandidate != null && bestScore >= LOW_CONFIDENCE) {
            BigDecimal confidence = BigDecimal.valueOf(bestScore).setScale(3, RoundingMode.HALF_UP);
            merge(edupageTeacher, bestCandidate, confidence, false);
            log.info("{} match: '{}' → '{}' (score={})",
                bestScore >= HIGH_CONFIDENCE ? "High-confidence" : "Low-confidence",
                edupageTeacher.getCyrillicName(),
                bestCandidate.getConsultationUsername(),
                confidence);
        } else {
            log.warn("No match found for EduPage teacher '{}' (best score={})",
                edupageTeacher.getCyrillicName(), String.format("%.3f", bestScore));
        }
    }

    /**
     * Merges consultation data into the EduPage teacher row and removes the
     * orphan consultation-only Teacher row.
     */
    private void merge(Teacher edupageTeacher, Teacher consultationTeacher,
                       BigDecimal confidence, boolean manual) {
        String username = consultationTeacher.getConsultationUsername();

        // Delete the orphan row first to release the UNIQUE slot before saving the merged row
        if (!consultationTeacher.getId().equals(edupageTeacher.getId())) {
            teacherRepo.delete(consultationTeacher);
            teacherRepo.flush();
        }

        edupageTeacher.setConsultationUsername(username);
        edupageTeacher.setMatchConfidence(confidence);
        edupageTeacher.setManualOverride(manual);
        teacherRepo.save(edupageTeacher);
    }

    /**
     * Token-aware similarity in [0, 1], robust to word order and extra name
     * tokens (e.g. a middle/maiden surname present on one side only).
     *
     * Modelled on the fuzzywuzzy token-set ratio: the shared tokens are compared
     * against the shared-plus-remainder strings, and a token-sort comparison acts
     * as a floor. A subset like "biljana tojtovska" inside "biljana tojtovska
     * ribarski" scores 1.0; a reordered "petrov zoran" vs "zoran petrov" also
     * scores 1.0, while genuinely different names stay low because their
     * remainders dominate.
     */
    public double tokenSetSimilarity(String a, String b) {
        if (a.isEmpty() && b.isEmpty()) return 1.0;
        if (a.isEmpty() || b.isEmpty()) return 0.0;

        TreeSet<String> ta = new TreeSet<>(Arrays.asList(a.split(" ")));
        TreeSet<String> tb = new TreeSet<>(Arrays.asList(b.split(" ")));

        TreeSet<String> intersection = new TreeSet<>(ta);
        intersection.retainAll(tb);
        TreeSet<String> remainderA = new TreeSet<>(ta);
        remainderA.removeAll(intersection);
        TreeSet<String> remainderB = new TreeSet<>(tb);
        remainderB.removeAll(intersection);

        String inter = String.join(" ", intersection);
        String combinedA = (inter + " " + String.join(" ", remainderA)).trim();
        String combinedB = (inter + " " + String.join(" ", remainderB)).trim();

        double shared      = similarity(inter, combinedA);     // common vs common+extraA
        double sharedOther = similarity(inter, combinedB);     // common vs common+extraB
        double both        = similarity(combinedA, combinedB); // full token-sorted comparison
        return Math.max(Math.max(shared, sharedOther), both);
    }

    // Levenshtein similarity in [0, 1]
    public double similarity(String a, String b) {
        if (a.isEmpty() && b.isEmpty()) return 1.0;
        if (a.isEmpty() || b.isEmpty()) return 0.0;
        int dist = levenshtein(a, b);
        int maxLen = Math.max(a.length(), b.length());
        return 1.0 - (double) dist / maxLen;
    }

    private int levenshtein(String a, String b) {
        int la = a.length(), lb = b.length();
        int[] prev = new int[lb + 1];
        int[] curr = new int[lb + 1];
        for (int j = 0; j <= lb; j++) prev[j] = j;
        for (int i = 1; i <= la; i++) {
            curr[0] = i;
            for (int j = 1; j <= lb; j++) {
                int cost = a.charAt(i - 1) == b.charAt(j - 1) ? 0 : 1;
                curr[j] = Math.min(Math.min(curr[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
            }
            int[] tmp = prev; prev = curr; curr = tmp;
        }
        return prev[lb];
    }
}
