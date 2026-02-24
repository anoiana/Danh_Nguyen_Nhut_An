package com.example.demo.features.scheduling.service;

import com.example.demo.features.scheduling.dto.AvailabilityDto;
import com.example.demo.features.scheduling.dto.DateBookingDto;
import com.example.demo.features.scheduling.entity.Availability;
import com.example.demo.features.scheduling.entity.DateBooking;
import com.example.demo.features.scheduling.repository.AvailabilityRepository;
import com.example.demo.features.matching.entity.Match;
import com.example.demo.features.matching.service.MatchService;
import com.example.demo.features.user.entity.User;
import com.example.demo.features.user.service.UserService;
import com.example.demo.infra.exception.ResourceNotFoundException;
import com.example.demo.infra.exception.BusinessLogicException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service managing user availability slots and orchestrating the initial match
 * coordination.
 */
@Service
@RequiredArgsConstructor
public class AvailabilityService {

    private final AvailabilityRepository availabilityRepository;
    private final UserService userService;
    private final MatchService matchService;
    private final MatchingEngineService matchingEngineService;
    private final DateBookingService dateBookingService;
    private final NotificationService notificationService;

    public void addAvailability(Long userId, LocalDateTime start, LocalDateTime end) {
        User user = userService.findByIdOrThrow(userId);

        if (dateBookingService.hasOverlap(userId, start, end)) {
            throw new BusinessLogicException("You already have a booking during this time slot!");
        }

        List<Availability> overlappingAvails = availabilityRepository.findOverlappingAvailabilities(userId, start, end);
        if (!overlappingAvails.isEmpty()) {
            throw new BusinessLogicException("This slot overlaps with your other availability slots!");
        }

        Availability availability = new Availability(user, start, end);
        availabilityRepository.save(availability);
    }

    @Transactional
    public String submitAvailability(Long userId, Long targetUserId) {
        User user = userService.findByIdOrThrow(userId);
        User target = userService.findByIdOrThrow(targetUserId);
        Match match = matchService.getMatchBetweenUsers(user, target);

        if (match == null) {
            throw new ResourceNotFoundException("Match not found between users " + userId + " and " + targetUserId);
        }

        List<Availability> userSlots = availabilityRepository.findByUser(user);
        if (userSlots.size() < 3) {
            throw new BusinessLogicException("You need to add at least 3 availability slots");
        }

        boolean isUser1 = match.getUser1().getId().equals(userId);

        if (match.getStatus() == Match.Status.WAITING_FOR_SCHEDULE) {
            match.setStatus(isUser1 ? Match.Status.PENDING_USER1_AVAIL : Match.Status.PENDING_USER2_AVAIL);

            notificationService.broadcastSchedulingUpdate(targetUserId,
                    com.example.demo.features.scheduling.dto.SchedulingNotification.builder()
                            .type("MATCH_STATUS_UPDATE")
                            .data(match.getStatus())
                            .message("The other person has submitted their availability!")
                            .build());

            return "PENDING";
        }

        else if ((isUser1 && match.getStatus() == Match.Status.PENDING_USER2_AVAIL) ||
                (!isUser1 && match.getStatus() == Match.Status.PENDING_USER1_AVAIL)) {
            DateBooking booking = matchingEngineService.executeMatching(match);
            return (booking != null) ? "SUCCESS" : "FAIL";
        }

        return "PENDING";
    }

    public DateBookingDto confirmBooking(Long bookingId, Long userId) {
        return dateBookingService.confirmBooking(bookingId, userId);
    }

    public void cancelBooking(Long bookingId, Long userId) {
        dateBookingService.cancelBooking(bookingId, userId);
    }

    public DateBookingDto getConfirmedBookingBetweenUsers(Long u1Id, Long u2Id) {
        return dateBookingService.getConfirmedBookingBetweenUsersDto(u1Id, u2Id);
    }

    public List<AvailabilityDto> getUserAvailabilities(Long userId) {
        User user = userService.findByIdOrThrow(userId);
        return availabilityRepository.findByUser(user).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public void deleteAvailability(Long id) {
        availabilityRepository.deleteById(id);
    }

    public boolean canChat(Long u1Id, Long u2Id) {
        return dateBookingService.canChat(u1Id, u2Id);
    }

    public List<DateBookingDto> getMyBookings(Long userId) {
        return dateBookingService.getMyBookings(userId);
    }

    private AvailabilityDto convertToDto(Availability entity) {
        AvailabilityDto dto = new AvailabilityDto();
        dto.setId(entity.getId());
        dto.setUserId(entity.getUser().getId());
        dto.setStartTime(entity.getStartTime());
        dto.setEndTime(entity.getEndTime());
        return dto;
    }
}
