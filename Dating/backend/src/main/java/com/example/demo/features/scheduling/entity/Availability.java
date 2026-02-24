package com.example.demo.features.scheduling.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import com.example.demo.features.user.entity.User;

@Entity
@Table(name = "availabilities")
@Data
@NoArgsConstructor
public class Availability {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private LocalDateTime startTime;

    @Column(nullable = false)
    private LocalDateTime endTime;

    // Constructor for easy testing/creation
    public Availability(User user, LocalDateTime startTime, LocalDateTime endTime) {
        this.user = user;
        this.startTime = startTime;
        this.endTime = endTime;
    }
}
