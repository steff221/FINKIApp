package com.finki.scheduler.repository;

import com.finki.scheduler.domain.Exam;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ExamRepository extends JpaRepository<Exam, Long> {

    List<Exam> findBySessionOrderByDateAscStartTimeAsc(String session);

    @Query("SELECT DISTINCT e.session FROM Exam e ORDER BY e.session DESC")
    List<String> findDistinctSessions();

    long deleteBySession(String session);

    @Query("""
        SELECT e FROM Exam e
        WHERE (:session IS NULL OR e.session = :session)
          AND (:q IS NULL OR LOWER(e.subjectName) LIKE LOWER(CONCAT('%', CAST(:q AS string), '%')))
        ORDER BY e.date ASC, e.startTime ASC, e.subjectName ASC
        """)
    List<Exam> search(@Param("session") String session, @Param("q") String q);
}
