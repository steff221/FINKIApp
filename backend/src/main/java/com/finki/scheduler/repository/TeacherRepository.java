package com.finki.scheduler.repository;

import com.finki.scheduler.domain.Teacher;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface TeacherRepository extends JpaRepository<Teacher, Long> {
    Optional<Teacher> findByEdupageId(String edupageId);
    Optional<Teacher> findByConsultationUsername(String username);

    @Query("SELECT t FROM Teacher t WHERE t.edupageId IS NOT NULL AND t.consultationUsername IS NULL")
    List<Teacher> findUnmatchedEdupageTeachers();

    List<Teacher> findByCanonicalNameContainingIgnoreCase(String query);
}
