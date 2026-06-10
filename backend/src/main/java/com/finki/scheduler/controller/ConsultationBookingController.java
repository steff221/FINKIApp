package com.finki.scheduler.controller;

import com.finki.scheduler.domain.ConsultationBooking;
import com.finki.scheduler.domain.User;
import com.finki.scheduler.dto.request.BookingRequest;
import com.finki.scheduler.repository.ConsultationBookingRepository;
import com.finki.scheduler.repository.ConsultationSlotRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/consultations")
@RequiredArgsConstructor
public class ConsultationBookingController {

    private final ConsultationSlotRepository slotRepo;
    private final ConsultationBookingRepository bookingRepo;

    /** Register the current user for a consultation slot. */
    @PostMapping("/{slotId}/book")
    @ResponseStatus(HttpStatus.CREATED)
    public void book(@PathVariable Long slotId,
                     @RequestBody BookingRequest req,
                     @AuthenticationPrincipal User user) {
        var slot = slotRepo.findById(slotId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Slot not found"));
        if (bookingRepo.existsBySlotIdAndUserId(slotId, user.getId())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Already registered for this slot");
        }
        bookingRepo.save(ConsultationBooking.builder()
            .slot(slot)
            .user(user)
            .reason(req.reason())
            .build());
    }

    /** Cancel the current user's registration for a slot. */
    @DeleteMapping("/{slotId}/book")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void cancel(@PathVariable Long slotId,
                       @AuthenticationPrincipal User user) {
        bookingRepo.findBySlotIdAndUserId(slotId, user.getId())
            .ifPresent(bookingRepo::delete);
    }

    /** Return slot IDs the current user has booked. */
    @GetMapping("/bookings/mine")
    public List<Long> mine(@AuthenticationPrincipal User user) {
        return bookingRepo.findSlotIdsByUserId(user.getId());
    }
}
