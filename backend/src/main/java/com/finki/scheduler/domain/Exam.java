package com.finki.scheduler.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;

/**
 * A single exam/colloquium entry from an exam-session timetable.
 *
 * Exam sessions are published as standalone spreadsheets (not the EduPage feed),
 * so subjects/rooms are stored as free text rather than linked to {@link Subject}
 * or {@link Classroom}. Entries are loaded via the admin CSV import endpoint and
 * grouped by {@code session} (e.g. "Јунска сесија 2025/26").
 */
@Entity
@Table(name = "exams")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Exam {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Exam session label, e.g. "Јунска сесија 2025/26". */
    @Column(nullable = false, length = 120)
    private String session;

    @Column(name = "subject_name", nullable = false, length = 300)
    private String subjectName;

    @Column(nullable = false)
    private LocalDate date;

    @Column(name = "start_time")
    private LocalTime startTime;

    @Column(name = "end_time")
    private LocalTime endTime;

    /** Free-text room(s), e.g. "Б2.1, Б2.2". */
    @Column(length = 200)
    private String rooms;

    @Column(columnDefinition = "TEXT")
    private String note;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();
}
