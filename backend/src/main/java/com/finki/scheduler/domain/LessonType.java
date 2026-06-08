package com.finki.scheduler.domain;

public enum LessonType {
    LECTURE, LAB, EXERCISE, COMBINED;

    public static LessonType fromSuffix(String suffix) {
        if (suffix == null) return LECTURE;
        return switch (suffix.trim()) {
            case "п"    -> LECTURE;
            case "ав"   -> LAB;
            case "в"    -> EXERCISE;
            case "п+ав" -> COMBINED;
            default     -> LECTURE;
        };
    }
}
