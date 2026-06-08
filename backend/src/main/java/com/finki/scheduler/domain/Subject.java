package com.finki.scheduler.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "subjects")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Subject {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "edupage_id", unique = true, nullable = false, length = 20)
    private String edupageId;

    @Column(name = "full_name", nullable = false, length = 300)
    private String fullName;

    @Column(name = "base_name", nullable = false, length = 300)
    private String baseName;

    @Enumerated(EnumType.STRING)
    @Column(name = "lesson_type", nullable = false, length = 20)
    private LessonType lessonType;
}
