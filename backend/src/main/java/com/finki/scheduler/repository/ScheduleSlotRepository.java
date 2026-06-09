package com.finki.scheduler.repository;

import com.finki.scheduler.domain.LessonType;
import com.finki.scheduler.domain.ScheduleSlot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ScheduleSlotRepository extends JpaRepository<ScheduleSlot, Long> {

    Optional<ScheduleSlot> findByEdupageCardId(String cardId);

    void deleteByEditionNumber(String editionNumber);

    @Query("""
        SELECT DISTINCT s FROM ScheduleSlot s
        JOIN FETCH s.subject subj
        LEFT JOIN FETCH s.classroom
        LEFT JOIN FETCH s.teachers
        LEFT JOIN FETCH s.studyClasses sc
        WHERE (:editionNumber IS NULL OR s.editionNumber = :editionNumber)
          AND (:year       IS NULL OR sc.year          = :year)
          AND (:programme  IS NULL OR sc.programmeCode = :programme)
          AND (:teacherId  IS NULL OR EXISTS (SELECT 1 FROM s.teachers t WHERE t.id = :teacherId))
          AND (:subjectId  IS NULL OR subj.id           = :subjectId)
          AND (:classroomId IS NULL OR s.classroom.id   = :classroomId)
          AND (:lessonType IS NULL OR subj.lessonType   = :lessonType)
          AND (:dayOfWeek  IS NULL OR s.dayOfWeek       = :dayOfWeek)
        ORDER BY s.dayOfWeek, s.startTime
        """)
    List<ScheduleSlot> findFiltered(
        @Param("editionNumber") String editionNumber,
        @Param("year")        Short year,
        @Param("programme")   String programme,
        @Param("teacherId")   Long teacherId,
        @Param("subjectId")   Long subjectId,
        @Param("classroomId") Long classroomId,
        @Param("lessonType")  LessonType lessonType,
        @Param("dayOfWeek")   Integer dayOfWeek
    );

    @Query("SELECT DISTINCT s.editionNumber FROM ScheduleSlot s WHERE s.editionNumber IS NOT NULL")
    List<String> findDistinctEditionNumbers();

    @Query("""
        SELECT s FROM ScheduleSlot s
        JOIN FETCH s.subject
        LEFT JOIN FETCH s.classroom
        LEFT JOIN FETCH s.teachers
        LEFT JOIN FETCH s.studyClasses
        WHERE s.id IN (
            SELECT uss.slot.id FROM UserScheduleSlot uss WHERE uss.user.id = :userId
        )
        ORDER BY s.dayOfWeek, s.startTime
        """)
    List<ScheduleSlot> findByUserId(@Param("userId") Long userId);
}
