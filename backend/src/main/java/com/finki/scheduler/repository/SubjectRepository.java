package com.finki.scheduler.repository;

import com.finki.scheduler.domain.Subject;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SubjectRepository extends JpaRepository<Subject, Long> {
    Optional<Subject> findByEdupageId(String edupageId);
}
