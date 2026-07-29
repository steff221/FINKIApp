package com.finki.scheduler.domain;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public enum LessonType {
    LECTURE, LAB, EXERCISE, COMBINED;

    private static final Logger log = LoggerFactory.getLogger(LessonType.class);

    /**
     * Reads the type out of the parenthesised suffix EduPage puts on a subject
     * name — {@code Бази на податоци (ав)}.
     *
     * <p>{@code ав} is <em>аудиториски</em> вежби, so it is an EXERCISE. It was
     * previously mapped to LAB, which put every exercise class in the faculty
     * under the wrong type and left EXERCISE with a single slot.
     *
     * <p>Anything unrecognised still falls back to LECTURE — a lesson with an
     * odd suffix is better shown as something than dropped — but it says so, so
     * a new suffix upstream is visible rather than silent.
     */
    public static LessonType fromSuffix(String suffix) {
        if (suffix == null) return LECTURE;
        return switch (suffix.trim()) {
            case "п"     -> LECTURE;
            case "ав", "в" -> EXERCISE;   // аудиториски вежби / вежби
            case "лв", "л" -> LAB;        // лабораториски вежби
            case "п+ав"  -> COMBINED;
            default -> {
                log.warn("Unrecognised lesson-type suffix '{}' — recording as LECTURE", suffix);
                yield LECTURE;
            }
        };
    }
}
