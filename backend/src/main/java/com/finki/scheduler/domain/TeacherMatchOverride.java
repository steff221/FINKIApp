package com.finki.scheduler.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

@Entity
@Table(name = "teacher_match_overrides")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TeacherMatchOverride {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "edupage_id", nullable = false, length = 20)
    private String edupageId;

    @Column(name = "consultation_username", nullable = false, length = 100)
    private String consultationUsername;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();
}
