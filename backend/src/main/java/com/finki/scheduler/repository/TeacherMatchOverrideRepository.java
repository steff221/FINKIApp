package com.finki.scheduler.repository;

import com.finki.scheduler.domain.TeacherMatchOverride;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface TeacherMatchOverrideRepository extends JpaRepository<TeacherMatchOverride, Long> {
    Optional<TeacherMatchOverride> findByEdupageId(String edupageId);
}
