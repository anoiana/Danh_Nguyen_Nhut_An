package com.example.demo.features.scheduling.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import com.example.demo.features.user.entity.User;

/**
 * Represents a scheduled date event between two users.
 * Orchestrates the flow from proposal -> venue confirmation -> attendance
 * feedback.
 */
@Entity
@Table(name = "date_bookings")
@Data
@NoArgsConstructor
public class DateBooking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "requester_id", nullable = false)
    private User requester;

    @ManyToOne
    @JoinColumn(name = "recipient_id", nullable = false)
    private User recipient;

    @Column(nullable = false)
    private LocalDateTime startTime;

    @Column(nullable = false)
    private LocalDateTime endTime;

    // Lifecycle: PROPOSED (waiting for venue confirmation),
    // CONFIRMED (locked in),
    // REJECTED/CANCELLED.
    @Column(nullable = false)
    private String status;

    private String venue;

    // Coordination fields: Both parties must click "Confirm Venue"
    // for the status to transition to CONFIRMED.
    private Boolean requesterConfirmed = false;
    private Boolean recipientConfirmed = false;

    // Post-Date Analytics: Tracking attendance and desire for future contact.
    private Boolean requesterAttended = null;
    private Boolean recipientAttended = null;
    private Boolean requesterWantsContact = null;
    private Boolean recipientWantsContact = null;

    // Privacy: Only set to true if BOTH expressing desire for contact.
    private Boolean contactExchanged = false;

    private LocalDateTime createdAt = LocalDateTime.now();
}
