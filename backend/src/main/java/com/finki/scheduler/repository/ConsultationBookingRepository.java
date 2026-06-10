package com.finki.scheduler.repository;

import com.finki.scheduler.domain.ConsultationBooking;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ConsultationBookingRepository extends JpaRepository<ConsultationBooking, Long> {

    long countBySlotId(Long slotId);

    boolean existsBySlotIdAndUserId(Long slotId, Long userId);

    Optional<ConsultationBooking> findBySlotIdAndUserId(Long slotId, Long userId);

    @Query("SELECT b.slot.id FROM ConsultationBooking b WHERE b.user.id = :userId")
    List<Long> findSlotIdsByUserId(@Param("userId") Long userId);
}
