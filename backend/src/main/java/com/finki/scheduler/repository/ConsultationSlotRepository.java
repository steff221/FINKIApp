package com.finki.scheduler.repository;

import com.finki.scheduler.domain.ConsultationSlot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ConsultationSlotRepository extends JpaRepository<ConsultationSlot, Long> {

    List<ConsultationSlot> findByTeacherIdOrderByDateAscStartTimeAsc(Long teacherId);

    @Modifying
    @Query("DELETE FROM ConsultationSlot c WHERE c.teacher.id = :teacherId")
    void deleteByTeacherId(@Param("teacherId") Long teacherId);

    @Query("""
        SELECT c FROM ConsultationSlot c
        JOIN FETCH c.teacher t
        WHERE LOWER(t.cyrillicName) LIKE LOWER(CONCAT('%', :query, '%'))
           OR LOWER(t.canonicalName) LIKE LOWER(CONCAT('%', :query, '%'))
        ORDER BY t.cyrillicName, c.date, c.startTime
        """)
    List<ConsultationSlot> searchByTeacherName(@Param("query") String query);
}
