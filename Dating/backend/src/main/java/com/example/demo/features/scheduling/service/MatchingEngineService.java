package com.example.demo.features.scheduling.service;

import com.example.demo.features.scheduling.dto.DateBookingDto;
import com.example.demo.features.scheduling.entity.Availability;
import com.example.demo.features.scheduling.entity.DateBooking;
import com.example.demo.features.scheduling.dto.SchedulingNotification;
import com.example.demo.features.scheduling.repository.AvailabilityRepository;
import com.example.demo.features.scheduling.repository.DateBookingRepository;
import com.example.demo.features.matching.entity.Match;
import com.example.demo.features.scheduling.entity.Venue;
import com.example.demo.features.user.entity.User;
import com.example.demo.features.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Core engine responsible for finding common time slots between two users
 * and initiating the dating proposal process.
 */
@Service
@RequiredArgsConstructor
public class MatchingEngineService {

    private final AvailabilityRepository availabilityRepository;
    private final DateBookingRepository dateBookingRepository;
    private final UserService userService;
    private final ActivityService activityService;
    private final NotificationService notificationService;
    private final VenueService venueService;

    /**
     * Orchestrates the matching process after both users have submitted their
     * availability.
     */
    public DateBooking executeMatching(Match match) {
        User u1 = match.getUser1();
        User u2 = match.getUser2();

        Availability common = findFirstCommonSlot(u1.getId(), u2.getId());

        if (common != null) {
            // GPS Midpoint Algorithm: select the venue closest to both users
            Venue venue = venueService.findBestVenue(u1, u2);
            String venueName = (venue != null) ? venue.getName() + " - " + venue.getAddress() : "TBD";

            DateBooking booking = new DateBooking();
            booking.setRequester(u1);
            booking.setRecipient(u2);
            booking.setStartTime(common.getStartTime());
            booking.setEndTime(common.getEndTime());
            booking.setVenue(venueName);
            booking.setStatus("PROPOSED");

            match.setStatus(Match.Status.PROPOSED);
            DateBooking saved = dateBookingRepository.save(booking);

            // Notify both users via WebSocket (Using DTO)
            SchedulingNotification notification = SchedulingNotification.builder()
                    .type("BOOKING_PROPOSED")
                    .data(convertToDto(saved))
                    .message("A matching time slot has been found!")
                    .build();

            notificationService.broadcastSchedulingUpdate(u1.getId(), notification);
            notificationService.broadcastSchedulingUpdate(u2.getId(), notification);

            activityService.logActivity(u1, "Found a matching date time with " + u2.getName() + "! ✨",
                    "SCHEDULING_PROPOSED");
            activityService.logActivity(u2, "Found a matching date time with " + u1.getName() + "! ✨",
                    "SCHEDULING_PROPOSED");

            return saved;
        } else {
            // Failure Path: Reset both users' availability
            List<Availability> list1 = availabilityRepository.findByUser(u1);
            List<Availability> list2 = availabilityRepository.findByUser(u2);
            availabilityRepository.deleteAll(list1);
            availabilityRepository.deleteAll(list2);

            match.setStatus(Match.Status.WAITING_FOR_SCHEDULE);

            SchedulingNotification failNotification = SchedulingNotification.builder()
                    .type("MATCHING_FAILED")
                    .message("No common time slot found. Please pick your availability again!")
                    .build();

            notificationService.broadcastSchedulingUpdate(u1.getId(), failNotification);
            notificationService.broadcastSchedulingUpdate(u2.getId(), failNotification);

            return null;
        }
    }

    /**
     * Find the first chronological overlap between two users' availabilities.
     */
    public Availability findFirstCommonSlot(Long user1Id, Long user2Id) {
        User u1 = userService.findByIdOrThrow(user1Id);
        User u2 = userService.findByIdOrThrow(user2Id);

        List<Availability> list1 = availabilityRepository.findByUser(u1);
        List<Availability> list2 = availabilityRepository.findByUser(u2);

        // Sorting ensures we find the earliest possible meeting time.
        list1.sort((a, b) -> a.getStartTime().compareTo(b.getStartTime()));
        list2.sort((a, b) -> a.getStartTime().compareTo(b.getStartTime()));

        for (Availability a : list1) {
            for (Availability b : list2) {
                // Same-day constraint for simpler dating logistics.
                if (!a.getStartTime().toLocalDate().equals(b.getStartTime().toLocalDate()))
                    continue;

                LocalDateTime maxStart = a.getStartTime().isAfter(b.getStartTime()) ? a.getStartTime()
                        : b.getStartTime();
                LocalDateTime minEnd = a.getEndTime().isBefore(b.getEndTime()) ? a.getEndTime() : b.getEndTime();

                if (maxStart.isBefore(minEnd)) {
                    long minutes = java.time.Duration.between(maxStart, minEnd).toMinutes();

                    // 90-minute minimum duration to ensure a quality dating experience.
                    if (minutes >= 90) {
                        // Double-check against actual CONFIRMED/PROPOSED bookings to prevent
                        // double-booking.
                        List<DateBooking> overlaps1 = dateBookingRepository.findOverlappingBookings(user1Id, maxStart,
                                minEnd);
                        List<DateBooking> overlaps2 = dateBookingRepository.findOverlappingBookings(user2Id, maxStart,
                                minEnd);

                        if (overlaps1.isEmpty() && overlaps2.isEmpty()) {
                            Availability commonSlot = new Availability();
                            commonSlot.setStartTime(maxStart);
                            commonSlot.setEndTime(minEnd);
                            return commonSlot;
                        }
                    }
                }
            }
        }
        return null;
    }

    private DateBookingDto convertToDto(DateBooking entity) {
        DateBookingDto dto = new DateBookingDto();
        dto.setId(entity.getId());
        dto.setRequesterId(entity.getRequester().getId());
        dto.setRequesterName(entity.getRequester().getName());
        dto.setRecipientId(entity.getRecipient().getId());
        dto.setRecipientName(entity.getRecipient().getName());
        dto.setStartTime(entity.getStartTime());
        dto.setEndTime(entity.getEndTime());
        dto.setStatus(entity.getStatus());
        dto.setVenue(entity.getVenue());
        dto.setRequesterConfirmed(entity.getRequesterConfirmed());
        dto.setRecipientConfirmed(entity.getRecipientConfirmed());
        dto.setRequesterAttended(entity.getRequesterAttended());
        dto.setRecipientAttended(entity.getRecipientAttended());
        dto.setRequesterWantsContact(entity.getRequesterWantsContact());
        dto.setRecipientWantsContact(entity.getRecipientWantsContact());
        dto.setContactExchanged(entity.getContactExchanged());
        return dto;
    }
}
