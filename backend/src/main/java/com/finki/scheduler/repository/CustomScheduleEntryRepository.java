package com.finki.scheduler.repository;

import com.finki.scheduler.domain.CustomScheduleEntry;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CustomScheduleEntryRepository extends JpaRepository<CustomScheduleEntry, Long> {
    List<CustomScheduleEntry> findByUserIdOrderByDayOfWeekAscStartTimeAsc(Long userId);
    Optional<CustomScheduleEntry> findByIdAndUserId(Long id, Long userId);
    void deleteByIdAndUserId(Long id, Long userId);
}
