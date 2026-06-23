package com.finki.scheduler.service;

import com.finki.scheduler.domain.Exam;
import com.finki.scheduler.domain.User;
import com.finki.scheduler.domain.UserSavedExam;
import com.finki.scheduler.repository.ExamRepository;
import com.finki.scheduler.repository.UserRepository;
import com.finki.scheduler.repository.UserSavedExamRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List; 

/** Manages the exams a user has pinned to their personal schedule (Мој Распоред). */
@Service
@RequiredArgsConstructor
public class SavedExamService {

    private final UserRepository         userRepo;
    private final ExamRepository         examRepo;
    private final UserSavedExamRepository savedExamRepo;

    @Transactional(readOnly = true)
    public List<Exam> getSavedExams(Long userId) {
        return savedExamRepo.findExamsByUserId(userId);
    }

    @Transactional
    public void addExam(Long userId, Long examId) {
        if (savedExamRepo.existsByUserIdAndExamId(userId, examId)) return;

        User user = userRepo.findById(userId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        Exam exam = examRepo.findById(examId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Exam not found"));

        savedExamRepo.save(UserSavedExam.builder().user(user).exam(exam).build());
    }

    @Transactional
    public void removeExam(Long userId, Long examId) {
        savedExamRepo.deleteByUserIdAndExamId(userId, examId);
    }
}
