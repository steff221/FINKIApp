package com.finki.scheduler.repository;

import com.finki.scheduler.domain.Classroom;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ClassroomRepository extends JpaRepository<Classroom, Long> {
    Optional<Classroom> findByEdupageId(String edupageId);
}
