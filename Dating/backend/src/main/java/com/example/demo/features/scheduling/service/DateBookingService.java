package com.example.demo.features.scheduling.service;

import com.example.demo.features.scheduling.dto.DateBookingDto;
import com.example.demo.features.scheduling.dto.SchedulingNotification;
import com.example.demo.features.scheduling.entity.DateBooking;
import com.example.demo.features.user.entity.User;
import com.example.demo.features.scheduling.repository.DateBookingRepository;
import com.example.demo.features.user.service.UserService;
import com.example.demo.features.matching.service.MatchService;
import com.example.demo.infra.exception.BookingConflictException;
import com.example.demo.infra.exception.BusinessLogicException;
import com.example.demo.infra.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service managing the lifecycle of a date booking, from initial request
 * to feedback submission and final contact exchange.
 */
@Service
@RequiredArgsConstructor
public class DateBookingService {

        private final DateBookingRepository dateBookingRepository;
        private final UserService userService;
        private final ActivityService activityService;
        private final MatchService matchService;
        private final NotificationService notificationService;

        /**
         * Creates a manual date invitation (outside the automated matching flow).
         */
        @Transactional
        public DateBookingDto createRequest(Long requesterId, Long recipientId, LocalDateTime start,
                        LocalDateTime end) {
                User requester = userService.findById(requesterId)
                                .orElseThrow(() -> new ResourceNotFoundException(
                                                "Requester not found with id: " + requesterId));
                User recipient = userService.findById(recipientId)
                                .orElseThrow(() -> new ResourceNotFoundException(
                                                "Recipient not found with id: " + recipientId));

                // Validate that neither user has a conflicting confirmed/pending date.
                if (!dateBookingRepository.findOverlappingBookings(requesterId, start, end).isEmpty()) {
                        throw new BookingConflictException("You already have another booking during this time slot!");
                }
                if (!dateBookingRepository.findOverlappingBookings(recipientId, start, end).isEmpty()) {
                        throw new BookingConflictException(
                                        "The other person already has another booking during this time slot!");
                }

                DateBooking booking = new DateBooking();
                booking.setRequester(requester);
                booking.setRecipient(recipient);
                booking.setStartTime(start);
                booking.setEndTime(end);
                booking.setStatus("PENDING");

                DateBooking saved = dateBookingRepository.save(booking);
                activityService.logActivity(recipient, requester.getName() + " just sent you a date invitation! 📅",
                                "BOOKING_REQUEST");
                return convertToDto(saved);
        }

        public List<DateBookingDto> getMyBookings(Long userId) {
                User user = userService.findById(userId)
                                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));
                return dateBookingRepository.findByRequesterOrRecipient(user, user)
                                .stream()
                                .filter(b -> !"CANCELLED".equals(b.getStatus()) && !"REJECTED".equals(b.getStatus()))
                                .map(this::convertToDto)
                                .collect(Collectors.toList());
        }

        /**
         * Updates the status of a pending request (Accept/Decline).
         */
        @Transactional
        public DateBookingDto updateStatus(Long bookingId, String status) {
                DateBooking booking = dateBookingRepository.findById(bookingId)
                                .orElseThrow(() -> new ResourceNotFoundException(
                                                "Booking not found with id: " + bookingId));
                booking.setStatus(status);

                DateBooking saved = dateBookingRepository.save(booking);
                String msg = status.equals("ACCEPTED") ? " accepted your date invitation! 😍"
                                : " declined the date invitation. 😢";
                activityService.logActivity(booking.getRequester(), booking.getRecipient().getName() + msg,
                                "BOOKING_RESPONSE");

                return convertToDto(saved);
        }

        /**
         * Processes post-date feedback and handles mutual contact exchange.
         */
        @Transactional
        public DateBookingDto submitFeedback(Long bookingId, Long userId, boolean attended, boolean wantsContact) {
                DateBooking booking = dateBookingRepository.findById(bookingId)
                                .orElseThrow(() -> new ResourceNotFoundException(
                                                "Booking not found with id: " + bookingId));

                if (booking.getRequester().getId().equals(userId)) {
                        booking.setRequesterAttended(attended);
                        booking.setRequesterWantsContact(attended && wantsContact);
                } else if (booking.getRecipient().getId().equals(userId)) {
                        booking.setRecipientAttended(attended);
                        booking.setRecipientWantsContact(attended && wantsContact);
                } else {
                        throw new BusinessLogicException("User " + userId + " is not part of booking " + bookingId);
                }

                // Mutual Interest Logic: Contact info is ONLY exchanged if BOTH parties
                // confirmed attendance and BOTH expressed a desire to keep in touch.
                boolean bothAttended = Boolean.TRUE.equals(booking.getRequesterAttended()) &&
                                Boolean.TRUE.equals(booking.getRecipientAttended());

                if (bothAttended &&
                                Boolean.TRUE.equals(booking.getRequesterWantsContact()) &&
                                Boolean.TRUE.equals(booking.getRecipientWantsContact())) {
                        booking.setContactExchanged(true);

                        activityService.logActivity(booking.getRequester(),
                                        "Mutual Interest! You and " + booking.getRecipient().getName()
                                                        + " have exchanged contact info! Check your Date Ticket. 📱",
                                        "CONTACT_EXCHANGED");
                        activityService.logActivity(booking.getRecipient(),
                                        "Mutual Interest! You and " + booking.getRequester().getName()
                                                        + " have exchanged contact info! Check your Date Ticket. 📱",
                                        "CONTACT_EXCHANGED");
                }

                return convertToDto(dateBookingRepository.save(booking));
        }

        /**
         * Finalizes a proposed date after both users click "Confirm Venue".
         */
        @Transactional
        public DateBookingDto confirmBooking(Long bookingId, Long userId) {
                DateBooking booking = dateBookingRepository.findById(bookingId)
                                .orElseThrow(() -> new ResourceNotFoundException(
                                                "Booking not found with id: " + bookingId));

                if (booking.getRequester().getId().equals(userId)) {
                        booking.setRequesterConfirmed(true);
                } else if (booking.getRecipient().getId().equals(userId)) {
                        booking.setRecipientConfirmed(true);
                } else {
                        throw new BusinessLogicException("User " + userId + " is not part of booking " + bookingId);
                }

                // If both users have confirmed, officially lock the date and update the Match
                // status.
                if (Boolean.TRUE.equals(booking.getRequesterConfirmed()) &&
                                Boolean.TRUE.equals(booking.getRecipientConfirmed())) {
                        booking.setStatus("CONFIRMED");
                        matchService.updateMatchStatus(booking.getRequester(), booking.getRecipient(),
                                        com.example.demo.features.matching.entity.Match.Status.SCHEDULED);
                }

                DateBooking saved = dateBookingRepository.save(booking);
                DateBookingDto dto = convertToDto(saved);

                // Real-time UI update on both sides.
                SchedulingNotification notification = SchedulingNotification.builder()
                                .type("BOOKING_UPDATE")
                                .data(dto)
                                .message(saved.getStatus().equals("CONFIRMED") ? "Date confirmed! 🥂"
                                                : "The other person has confirmed the venue!")
                                .build();

                notificationService.broadcastSchedulingUpdate(booking.getRequester().getId(), notification);
                notificationService.broadcastSchedulingUpdate(booking.getRecipient().getId(), notification);

                if ("CONFIRMED".equals(saved.getStatus())) {
                        activityService.logActivity(booking.getRequester(),
                                        "The date with " + booking.getRecipient().getName() + " has been confirmed! 🥂",
                                        "SCHEDULING_CONFIRMED");
                        activityService.logActivity(booking.getRecipient(),
                                        "The date with " + booking.getRequester().getName() + " has been confirmed! 🥂",
                                        "SCHEDULING_CONFIRMED");
                } else {
                        User other = booking.getRequester().getId().equals(userId) ? booking.getRecipient()
                                        : booking.getRequester();
                        activityService.logActivity(other, "The other person has confirmed the dating venue! ⏳",
                                        "SCHEDULING_UPDATE");
                }

                return dto;
        }

        /**
         * Handles cancellation with penalty enforcement for "anti-flaker" protection.
         */
        @Transactional
        public void cancelBooking(Long bookingId, Long cancellingUserId) {
                DateBooking booking = dateBookingRepository.findById(bookingId)
                                .orElseThrow(() -> new ResourceNotFoundException(
                                                "Booking not found with id: " + bookingId));

                // Penalty Enforcement: Cancelling a CONFIRMED date is discouraged.
                if ("CONFIRMED".equals(booking.getStatus())) {
                        User user = userService.findById(cancellingUserId)
                                        .orElseThrow(() -> new ResourceNotFoundException(
                                                        "User not found with id: " + cancellingUserId));
                        user.setPenalizedUntil(LocalDateTime.now().plusDays(1));
                        userService.save(user);

                        activityService.logActivity(user,
                                        "You cancelled a confirmed date. As a penalty, you won't see new profiles for 24h. ⚠️",
                                        "PENALTY_NOTICE");
                }

                // Reset match status to allow rescheduling.
                matchService.updateMatchStatus(booking.getRequester(), booking.getRecipient(),
                                com.example.demo.features.matching.entity.Match.Status.WAITING_FOR_SCHEDULE);

                SchedulingNotification notification = SchedulingNotification.builder()
                                .type("MATCHING_FAILED")
                                .message("This booking has been cancelled. Please pick another time slot! 🔄")
                                .build();

                notificationService.broadcastSchedulingUpdate(booking.getRequester().getId(), notification);
                notificationService.broadcastSchedulingUpdate(booking.getRecipient().getId(), notification);

                activityService.logActivity(booking.getRequester(),
                                "The booking with " + booking.getRecipient().getName() + " has been cancelled.",
                                "SCHEDULING_CANCELED");
                activityService.logActivity(booking.getRecipient(),
                                "The booking with " + booking.getRequester().getName() + " has been cancelled.",
                                "SCHEDULING_CANCELED");

                booking.setStatus("CANCELLED");
                dateBookingRepository.save(booking);
        }

        /**
         * Chat Unlock Logic: Users can only chat within a small window
         * around the date time (4h before, 2h after).
         */
        public boolean canChat(Long u1Id, Long u2Id) {
                DateBooking booking = getConfirmedBookingBetweenUsers(u1Id, u2Id);
                if (booking == null || !"CONFIRMED".equals(booking.getStatus()))
                        return false;

                LocalDateTime now = LocalDateTime.now();
                LocalDateTime startTime = booking.getStartTime();
                return now.isAfter(startTime.minusHours(4)) && now.isBefore(startTime.plusHours(2));
        }

        /**
         * Retrieves the active date agreement between two users.
         */
        public DateBooking getConfirmedBookingBetweenUsers(Long u1Id, Long u2Id) {
                List<DateBooking> bookings = dateBookingRepository.findConfirmedBookingBetweenUsers(u1Id, u2Id);
                if (bookings.isEmpty()) {
                        // Look for PROPOSED status if no confirmed date exists.
                        return dateBookingRepository.findAll().stream()
                                        .filter(b -> (b.getRequester().getId().equals(u1Id)
                                                        && b.getRecipient().getId().equals(u2Id)) ||
                                                        (b.getRequester().getId().equals(u2Id)
                                                                        && b.getRecipient().getId().equals(u1Id)))
                                        .filter(b -> "PROPOSED".equals(b.getStatus()))
                                        .findFirst().orElse(null);
                }
                return bookings.get(0);
        }

        public DateBookingDto getConfirmedBookingBetweenUsersDto(Long u1Id, Long u2Id) {
                DateBooking entity = getConfirmedBookingBetweenUsers(u1Id, u2Id);
                return entity != null ? convertToDto(entity) : null;
        }

        public DateBookingDto getBookingById(Long id) {
                DateBooking booking = dateBookingRepository.findById(id)
                                .orElseThrow(() -> new ResourceNotFoundException("Booking not found with id: " + id));
                return convertToDto(booking);
        }

        public boolean hasOverlap(Long userId, LocalDateTime start, LocalDateTime end) {
                return !dateBookingRepository.findOverlappingBookings(userId, start, end).isEmpty();
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
                dto.setRequesterAvatar(entity.getRequester().getAvatarUrl());
                dto.setRecipientAvatar(entity.getRecipient().getAvatarUrl());

                // Reveal contact info only after mutual consent
                if (Boolean.TRUE.equals(entity.getContactExchanged())) {
                        dto.setRequesterEmail(entity.getRequester().getEmail());
                        dto.setRecipientEmail(entity.getRecipient().getEmail());
                }

                return dto;
        }
}
