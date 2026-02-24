package com.example.demo.features.scheduling.service;

import com.example.demo.features.matching.entity.Match;
import com.example.demo.features.scheduling.entity.Availability;
import com.example.demo.features.scheduling.entity.DateBooking;
import com.example.demo.features.scheduling.repository.AvailabilityRepository;
import com.example.demo.features.scheduling.repository.DateBookingRepository;
import com.example.demo.features.user.entity.User;
import com.example.demo.features.user.service.UserService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class MatchingEngineServiceTest {

    @Mock
    private AvailabilityRepository availabilityRepository;
    @Mock
    private DateBookingRepository dateBookingRepository;
    @Mock
    private UserService userService;
    @Mock
    private ActivityService activityService;
    @Mock
    private NotificationService notificationService;

    @InjectMocks
    private MatchingEngineService matchingEngineService;

    private User user1;
    private User user2;
    private Match match;

    @BeforeEach
    void setUp() {
        user1 = new User();
        user1.setId(1L);
        user1.setName("User 1");

        user2 = new User();
        user2.setId(2L);
        user2.setName("User 2");

        match = new Match();
        match.setUser1(user1);
        match.setUser2(user2);
    }

    @Test
    void testFindFirstCommonSlot_Success() {
        // Arrange: User 1 and User 2 have overlapping slots on the same day (Monday
        // 10:00 - 12:00)
        LocalDateTime today = LocalDateTime.now().withHour(10).withMinute(0);

        Availability avail1 = new Availability(user1, today, today.plusHours(3)); // 10:00 - 13:00
        Availability avail2 = new Availability(user2, today.plusHours(1), today.plusHours(4)); // 11:00 - 14:00

        when(userService.findById(1L)).thenReturn(Optional.of(user1));
        when(userService.findById(2L)).thenReturn(Optional.of(user2));
        when(availabilityRepository.findByUser(user1)).thenReturn(new ArrayList<>(List.of(avail1)));
        when(availabilityRepository.findByUser(user2)).thenReturn(new ArrayList<>(List.of(avail2)));
        when(dateBookingRepository.findOverlappingBookings(any(), any(), any())).thenReturn(new ArrayList<>());

        // Act
        Availability result = matchingEngineService.findFirstCommonSlot(1L, 2L);

        // Assert
        assertNotNull(result);
        assertEquals(today.plusHours(1), result.getStartTime()); // 11:00
        assertEquals(today.plusHours(3), result.getEndTime()); // 13:00 (120 mins > 90 mins)
    }

    @Test
    void testFindFirstCommonSlot_TooShort() {
        // Arrange: Overlap is only 30 mins
        LocalDateTime today = LocalDateTime.now().withHour(10).withMinute(0);

        Availability avail1 = new Availability(user1, today, today.plusMinutes(60)); // 10:00 - 11:00
        Availability avail2 = new Availability(user2, today.plusMinutes(30), today.plusMinutes(90)); // 10:30 - 11:30

        when(userService.findById(1L)).thenReturn(Optional.of(user1));
        when(userService.findById(2L)).thenReturn(Optional.of(user2));
        when(availabilityRepository.findByUser(user1)).thenReturn(new ArrayList<>(List.of(avail1)));
        when(availabilityRepository.findByUser(user2)).thenReturn(new ArrayList<>(List.of(avail2)));

        // Act
        Availability result = matchingEngineService.findFirstCommonSlot(1L, 2L);

        // Assert
        assertNull(result);
    }

    @Test
    void testFindFirstCommonSlot_DifferentDays() {
        // Arrange: Slots on successive days
        LocalDateTime today = LocalDateTime.now().withHour(10).withMinute(0);
        LocalDateTime tomorrow = today.plusDays(1);

        Availability avail1 = new Availability(user1, today, today.plusHours(2));
        Availability avail2 = new Availability(user2, tomorrow, tomorrow.plusHours(2));

        when(userService.findById(1L)).thenReturn(Optional.of(user1));
        when(userService.findById(2L)).thenReturn(Optional.of(user2));
        when(availabilityRepository.findByUser(user1)).thenReturn(new ArrayList<>(List.of(avail1)));
        when(availabilityRepository.findByUser(user2)).thenReturn(new ArrayList<>(List.of(avail2)));

        // Act
        Availability result = matchingEngineService.findFirstCommonSlot(1L, 2L);

        // Assert
        assertNull(result);
    }

    @Test
    void testExecuteMatching_Success() {
        // Arrange
        LocalDateTime today = LocalDateTime.now().withHour(10).withMinute(0);
        Availability common = new Availability(user1, today, today.plusHours(2));

        // Mock findFirstCommonSlot behavior indirectly by mocking its dependencies
        when(userService.findById(1L)).thenReturn(Optional.of(user1));
        when(userService.findById(2L)).thenReturn(Optional.of(user2));
        when(availabilityRepository.findByUser(any())).thenReturn(new ArrayList<>(List.of(common)));
        when(dateBookingRepository.findOverlappingBookings(any(), any(), any())).thenReturn(new ArrayList<>());
        when(dateBookingRepository.save(any())).thenAnswer(i -> i.getArguments()[0]);

        // Act
        DateBooking booking = matchingEngineService.executeMatching(match);

        // Assert
        assertNotNull(booking);
        assertEquals("PROPOSED", booking.getStatus());
        assertEquals(Match.Status.PROPOSED, match.getStatus());
        verify(dateBookingRepository, times(1)).save(any());
        verify(notificationService, times(2)).broadcastSchedulingUpdate(any(), any());
    }

    @Test
    void testExecuteMatching_FailResetsAvailabilities() {
        // Arrange: No common slot found
        when(userService.findById(1L)).thenReturn(Optional.of(user1));
        when(userService.findById(2L)).thenReturn(Optional.of(user2));
        when(availabilityRepository.findByUser(any())).thenReturn(new ArrayList<>());

        // Act
        DateBooking booking = matchingEngineService.executeMatching(match);

        // Assert
        assertNull(booking);
        assertEquals(Match.Status.WAITING_FOR_SCHEDULE, match.getStatus());
        verify(availabilityRepository, atLeastOnce()).deleteAll(any());
        verify(notificationService, times(2)).broadcastSchedulingUpdate(any(), any());
    }
}
