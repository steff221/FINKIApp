package com.finki.scheduler.service;

import com.finki.scheduler.domain.CustomScheduleEntry;
import com.finki.scheduler.domain.LessonType;
import com.finki.scheduler.domain.User;
import com.finki.scheduler.dto.request.CustomEntryRequest;
import com.finki.scheduler.dto.response.CustomEntryResponse;
import com.finki.scheduler.repository.CustomScheduleEntryRepository;
import com.finki.scheduler.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class CustomScheduleService {

    private final CustomScheduleEntryRepository repo;
    private final UserRepository userRepo;

    @Transactional(readOnly = true)
    public List<CustomEntryResponse> getAll(Long userId) {
        return repo.findByUserIdOrderByDayOfWeekAscStartTimeAsc(userId)
            .stream().map(CustomEntryResponse::from).toList();
    }

    @Transactional
    public CustomEntryResponse create(Long userId, CustomEntryRequest req) {
        User user = userRepo.findById(userId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));

        CustomScheduleEntry entry = CustomScheduleEntry.builder()
            .user(user)
            .title(req.title())
            .professor(req.professor())
            .entryType(LessonType.valueOf(req.entryType()))
            .dayOfWeek(req.dayOfWeek())
            .startTime(LocalTime.parse(req.startTime()))
            .endTime(LocalTime.parse(req.endTime()))
            .room(req.room())
            .color(req.color())
            .build();

        return CustomEntryResponse.from(repo.save(entry));
    }

    @Transactional
    public CustomEntryResponse update(Long userId, Long id, CustomEntryRequest req) {
        CustomScheduleEntry entry = repo.findByIdAndUserId(id, userId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));

        entry.setTitle(req.title());
        entry.setProfessor(req.professor());
        entry.setEntryType(LessonType.valueOf(req.entryType()));
        entry.setDayOfWeek(req.dayOfWeek());
        entry.setStartTime(LocalTime.parse(req.startTime()));
        entry.setEndTime(LocalTime.parse(req.endTime()));
        entry.setRoom(req.room());
        entry.setColor(req.color());

        return CustomEntryResponse.from(repo.save(entry));
    }

    @Transactional
    public void delete(Long userId, Long id) {
        if (repo.findByIdAndUserId(id, userId).isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND);
        }
        repo.deleteByIdAndUserId(id, userId);
    }
}
