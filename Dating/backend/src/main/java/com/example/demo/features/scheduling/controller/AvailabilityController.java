package com.example.demo.features.scheduling.controller;

import com.example.demo.features.scheduling.dto.AvailabilityDto;
import com.example.demo.features.scheduling.dto.AvailabilityRequest;
import com.example.demo.features.scheduling.dto.DateBookingDto;
import com.example.demo.features.scheduling.service.AvailabilityService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

/**
 * API Endpoints for managing user availability slots and match coordination.
 */
@RestController
@RequestMapping("/api/availabilities")
@RequiredArgsConstructor
public class AvailabilityController {

    private final AvailabilityService availabilityService;

    /**
     * Records a new availability slot for the user.
     */
    @PostMapping
    public ResponseEntity<String> addAvailability(@RequestBody AvailabilityRequest request) {
        availabilityService.addAvailability(
                request.getUserId(),
                request.getStartTime(),
                request.getEndTime());
        return ResponseEntity.ok("Availability added successfully.");
    }

    /**
     * Submits the chosen slots and triggers the matching engine if both users are
     * ready.
     */
    @PostMapping("/submit")
    public ResponseEntity<String> submitAvailability(
            @RequestParam Long userId,
            @RequestParam Long targetUserId) {
        String result = availabilityService.submitAvailability(userId, targetUserId);
        return ResponseEntity.ok(result);
    }

    /**
     * Confirms the venue for a proposed booking.
     */
    @PostMapping("/confirm")
    public ResponseEntity<DateBookingDto> confirmBooking(
            @RequestParam Long bookingId,
            @RequestParam Long userId) {
        return ResponseEntity.ok(availabilityService.confirmBooking(bookingId, userId));
    }

    /**
     * Cancels a booking.
     */
    @DeleteMapping("/booking/{id}")
    public ResponseEntity<String> cancelBooking(@PathVariable Long id, @RequestParam Long userId) {
        availabilityService.cancelBooking(id, userId);
        return ResponseEntity.ok("Booking canceled successfully.");
    }

    /**
     * Retrieves the confirmed or proposed booking between two users.
     */
    @GetMapping("/booking")
    public ResponseEntity<DateBookingDto> getBooking(
            @RequestParam Long u1Id,
            @RequestParam Long u2Id) {
        DateBookingDto booking = availabilityService.getConfirmedBookingBetweenUsers(u1Id, u2Id);
        if (booking != null) {
            return ResponseEntity.ok(booking);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * Retrieves all availability slots for a specific user.
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<AvailabilityDto>> getUserAvailabilities(@PathVariable Long userId) {
        return ResponseEntity.ok(availabilityService.getUserAvailabilities(userId));
    }

    /**
     * Deletes a specific availability slot.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<String> deleteAvailability(@PathVariable Long id) {
        availabilityService.deleteAvailability(id);
        return ResponseEntity.ok("Deleted successfully");
    }

    /**
     * Retrieves all bookings (Proposed, Confirmed) for the current user.
     */
    @GetMapping("/my")
    public ResponseEntity<List<DateBookingDto>> getMyBookings(@RequestParam Long userId) {
        return ResponseEntity.ok(availabilityService.getMyBookings(userId));
    }
}
