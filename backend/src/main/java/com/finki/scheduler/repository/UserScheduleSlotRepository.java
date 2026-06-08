package com.finki.scheduler.repository;

import com.finki.scheduler.domain.UserScheduleSlot;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserScheduleSlotRepository extends JpaRepository<UserScheduleSlot, Long> {
    boolean existsByUserIdAndSlotId(Long userId, Long slotId);
    Optional<UserScheduleSlot> findByUserIdAndSlotId(Long userId, Long slotId);
    void deleteByUserIdAndSlotId(Long userId, Long slotId);
}
