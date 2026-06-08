package com.finki.scheduler.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "study_classes")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class StudyClass {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "edupage_id", unique = true, nullable = false, length = 20)
    private String edupageId;

    @Column(nullable = false, length = 100)
    private String name;

    private Short year;

    @Column(name = "programme_code", length = 30)
    private String programmeCode;

    @Column(length = 10)
    private String colour;
}
