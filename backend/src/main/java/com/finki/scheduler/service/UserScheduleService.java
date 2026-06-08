package com.finki.scheduler.service;

import com.finki.scheduler.domain.ScheduleSlot;
import com.finki.scheduler.domain.User;
import com.finki.scheduler.domain.UserScheduleSlot;
import com.finki.scheduler.repository.ScheduleSlotRepository;
import com.finki.scheduler.repository.UserRepository;
import com.finki.scheduler.repository.UserScheduleSlotRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class UserScheduleService {

    private final UserRepository            userRepo;
    private final ScheduleSlotRepository    slotRepo;
    private final UserScheduleSlotRepository userSlotRepo;

    @Transactional(readOnly = true)
    public List<ScheduleSlot> getSchedule(Long userId) {
        return slotRepo.findByUserId(userId);
    }

    @Transactional
    public void addSlot(Long userId, Long slotId) {
        if (userSlotRepo.existsByUserIdAndSlotId(userId, slotId)) return;

        User user = userRepo.findById(userId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));
        ScheduleSlot slot = slotRepo.findById(slotId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Slot not found"));

        userSlotRepo.save(UserScheduleSlot.builder().user(user).slot(slot).build());
    }

    @Transactional
    public void removeSlot(Long userId, Long slotId) {
        userSlotRepo.deleteByUserIdAndSlotId(userId, slotId);
    }

    /**
     * Returns all pairs of slots in the user's schedule that conflict.
     * Two slots conflict when: same dayOfWeek AND startA < endB AND startB < endA.
     */
    @Transactional(readOnly = true)
    public List<long[]> detectConflicts(Long userId) {
        List<ScheduleSlot> slots = slotRepo.findByUserId(userId);
        return findConflicts(slots);
    }

    // Package-visible for unit testing
    static List<long[]> findConflicts(List<ScheduleSlot> slots) {
        List<long[]> conflicts = new java.util.ArrayList<>();
        for (int i = 0; i < slots.size(); i++) {
            for (int j = i + 1; j < slots.size(); j++) {
                ScheduleSlot a = slots.get(i);
                ScheduleSlot b = slots.get(j);
                if (overlaps(a, b)) {
                    conflicts.add(new long[]{a.getId(), b.getId()});
                }
            }
        }
        return conflicts;
    }

    static boolean overlaps(ScheduleSlot a, ScheduleSlot b) {
        if (!a.getDayOfWeek().equals(b.getDayOfWeek())) return false;
        LocalTime startA = a.getStartTime(), endA = a.getEndTime();
        LocalTime startB = b.getStartTime(), endB = b.getEndTime();
        return startA.isBefore(endB) && startB.isBefore(endA);
    }
}
