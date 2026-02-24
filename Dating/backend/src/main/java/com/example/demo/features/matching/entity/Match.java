package com.example.demo.features.matching.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import com.example.demo.features.user.entity.User;

/**
 * Represents a mutual connection between two users.
 * Tracks the coordination progress from the first like to a confirmed date.
 */
@Entity
@Table(name = "matches")
@Data
@NoArgsConstructor
public class Match {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Symmetry: user1 always has the smaller ID to prevent duplicate rows.
    @ManyToOne
    @JoinColumn(name = "user1_id", nullable = false)
    private User user1;

    @ManyToOne
    @JoinColumn(name = "user2_id", nullable = false)
    private User user2;

    @Column(nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Enumerated(EnumType.STRING)
    private Status status = Status.WAITING_FOR_SCHEDULE;

    /**
     * Coordination Lifecycle States:
     * - WAITING_FOR_SCHEDULE: Initial state, no one submitted slots yet.
     * - PENDING_USERX_AVAIL: One person submitted, waiting for the other.
     * - PROPOSED: Both submitted, engine found a slot, waiting for venue
     * confirmation.
     * - SCHEDULED: Date confirmed.
     */
    public enum Status {
        WAITING_FOR_SCHEDULE,
        PENDING_USER1_AVAIL,
        PENDING_USER2_AVAIL,
        PROPOSED,
        SCHEDULED,
        COMPLETED,
        CANCELLED
    }

    public Match(User user1, User user2) {
        this.user1 = user1;
        this.user2 = user2;
        this.createdAt = LocalDateTime.now();
        this.status = Status.WAITING_FOR_SCHEDULE;
    }
}
