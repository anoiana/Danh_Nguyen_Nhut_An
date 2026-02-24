package com.example.demo.features.scheduling.controller;

import com.example.demo.features.scheduling.dto.DateBookingDto;
import com.example.demo.features.scheduling.service.DateBookingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Controller for manual date invitations and post-date feedback.
 */
@RestController
@RequestMapping("/api/bookings")
@RequiredArgsConstructor
public class DateBookingController {

    private final DateBookingService dateBookingService;

    /**
     * Creates a manual date invitation.
     */
    @PostMapping("/request")
    public ResponseEntity<DateBookingDto> createRequest(
            @RequestParam Long requesterId,
            @RequestParam Long recipientId,
            @RequestParam String startTime,
            @RequestParam String endTime) {
        LocalDateTime start = LocalDateTime.parse(startTime);
        LocalDateTime end = LocalDateTime.parse(endTime);
        return ResponseEntity.ok(dateBookingService.createRequest(requesterId, recipientId, start, end));
    }

    /**
     * Retrieves all bookings (Proposed, Confirmed, Pending) for the current user.
     */
    @GetMapping("/my")
    public ResponseEntity<List<DateBookingDto>> getMyBookings(@RequestParam Long userId) {
        return ResponseEntity.ok(dateBookingService.getMyBookings(userId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<DateBookingDto> getBookingById(@PathVariable Long id) {
        return ResponseEntity.ok(dateBookingService.getBookingById(id));
    }

    /**
     * Accepts or declines a manual date invitation.
     */
    @PostMapping("/{id}/status")
    public ResponseEntity<DateBookingDto> updateStatus(
            @PathVariable Long id,
            @RequestParam String status) {
        return ResponseEntity.ok(dateBookingService.updateStatus(id, status));
    }

    /**
     * Submits feedback after a date occurs (Attendance and Contact Desire).
     */
    @PostMapping("/{id}/feedback")
    public ResponseEntity<DateBookingDto> submitFeedback(
            @PathVariable Long id,
            @RequestParam Long userId,
            @RequestParam boolean attended,
            @RequestParam boolean wantsContact) {
        return ResponseEntity.ok(dateBookingService.submitFeedback(id, userId, attended, wantsContact));
    }
}
