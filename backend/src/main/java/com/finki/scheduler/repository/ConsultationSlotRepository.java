package com.finki.scheduler.repository;

import com.finki.scheduler.domain.ConsultationSlot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ConsultationSlotRepository extends JpaRepository<ConsultationSlot, Long> {

    @Query("""
        SELECT c FROM ConsultationSlot c
        JOIN FETCH c.teacher t
        WHERE t.id = :teacherId
        ORDER BY c.date ASC, c.startTime ASC
        """)
    List<ConsultationSlot> findByTeacherIdOrderByDateAscStartTimeAsc(@Param("teacherId") Long teacherId);

    @Modifying
    @Query("DELETE FROM ConsultationSlot c WHERE c.teacher.id = :teacherId")
    void deleteByTeacherId(@Param("teacherId") Long teacherId);

    /**
     * Move all slots from one teacher to another. Used when a consultation-only
     * teacher is merged into its matched EduPage teacher: the slots must be
     * re-pointed before the orphan row is deleted, otherwise the teacher_id
     * ON DELETE CASCADE would wipe the slots scraped in the same run.
     */
    @Modifying
    @Query(value = "UPDATE consultation_slots SET teacher_id = :newTeacherId WHERE teacher_id = :oldTeacherId",
           nativeQuery = true)
    void reassignTeacher(@Param("oldTeacherId") Long oldTeacherId, @Param("newTeacherId") Long newTeacherId);

    @Query("""
        SELECT c FROM ConsultationSlot c
        JOIN FETCH c.teacher t
        WHERE LOWER(t.cyrillicName) LIKE LOWER(CONCAT('%', :query, '%'))
           OR LOWER(t.canonicalName) LIKE LOWER(CONCAT('%', :query, '%'))
        ORDER BY t.cyrillicName, c.date, c.startTime
        """)
    List<ConsultationSlot> searchByTeacherName(@Param("query") String query);
}
