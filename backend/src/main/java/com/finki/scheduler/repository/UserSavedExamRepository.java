package com.finki.scheduler.repository;

import com.finki.scheduler.domain.Exam;
import com.finki.scheduler.domain.UserSavedExam;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface UserSavedExamRepository extends JpaRepository<UserSavedExam, Long> {
    boolean existsByUserIdAndExamId(Long userId, Long examId);
    void deleteByUserIdAndExamId(Long userId, Long examId);

    /** The user's pinned exams, soonest first. */
    @Query("select u.exam from UserSavedExam u where u.user.id = :userId "
         + "order by u.exam.date asc, u.exam.startTime asc")
    List<Exam> findExamsByUserId(@Param("userId") Long userId);
}
