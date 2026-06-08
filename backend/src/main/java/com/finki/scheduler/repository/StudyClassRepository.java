package com.finki.scheduler.repository;

import com.finki.scheduler.domain.StudyClass;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface StudyClassRepository extends JpaRepository<StudyClass, Long> {
    Optional<StudyClass> findByEdupageId(String edupageId);

    @Query("SELECT DISTINCT sc.programmeCode FROM StudyClass sc WHERE sc.programmeCode IS NOT NULL ORDER BY sc.programmeCode")
    List<String> findDistinctProgrammeCodes();

    @Query("SELECT DISTINCT sc.year FROM StudyClass sc WHERE sc.year IS NOT NULL ORDER BY sc.year")
    List<Short> findDistinctYears();
}
