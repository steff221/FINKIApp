package com.finki.scheduler.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "classrooms")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Classroom {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "edupage_id", unique = true, nullable = false, length = 20)
    private String edupageId;

    @Column(nullable = false, length = 200)
    private String name;

    @Column(name = "short_name", length = 100)
    private String shortName;
}
