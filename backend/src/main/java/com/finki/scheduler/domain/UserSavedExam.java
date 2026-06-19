package com.finki.scheduler.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

/** An {@link Exam} a user has pinned to their personal schedule (Мој Распоред). */
@Entity
@Table(
    name = "user_saved_exams",
    uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "exam_id"})
)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UserSavedExam {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exam_id", nullable = false)
    private Exam exam;

    @Column(name = "added_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant addedAt = Instant.now();
}
