package com.finki.scheduler.repository;

import com.finki.scheduler.domain.ConsultationBooking;
import com.finki.scheduler.domain.ConsultationSlot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ConsultationBookingRepository extends JpaRepository<ConsultationBooking, Long> {

    long countBySlotId(Long slotId);

    /**
     * Booking totals for every slot that has at least one, as {slotId, count}
     * rows. Plain JPQL tuples rather than a projection interface: this is read
     * once per consultations request and mapped straight into a Map.
     */
    @Query("SELECT b.slot.id, COUNT(b) FROM ConsultationBooking b GROUP BY b.slot.id")
    List<Object[]> countBookingsPerSlot();

    boolean existsBySlotIdAndUserId(Long slotId, Long userId);

    Optional<ConsultationBooking> findBySlotIdAndUserId(Long slotId, Long userId);

    @Query("SELECT b.slot.id FROM ConsultationBooking b WHERE b.user.id = :userId")
    List<Long> findSlotIdsByUserId(@Param("userId") Long userId);

    @Query("SELECT s FROM ConsultationBooking b JOIN b.slot s JOIN FETCH s.teacher "
         + "WHERE b.user.id = :userId ORDER BY s.date, s.startTime")
    List<ConsultationSlot> findSlotsByUserId(@Param("userId") Long userId);
}
