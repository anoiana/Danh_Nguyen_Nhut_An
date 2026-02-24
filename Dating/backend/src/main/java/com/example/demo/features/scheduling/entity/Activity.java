package com.example.demo.features.scheduling.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import com.example.demo.features.user.entity.User;

@Entity
@Table(name = "activities")
@Data
@NoArgsConstructor
public class Activity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user; // The user who receives the notification

    @Column(nullable = false)
    private String content; // Content of the notification

    private String type; // MATCH, LIKE, BOOKING_REQUEST, BOOKING_RESPONSE

    private Boolean isRead = false;

    private LocalDateTime createdAt = LocalDateTime.now();

    public Activity(User user, String content, String type) {
        this.user = user;
        this.content = content;
        this.type = type;
        this.createdAt = LocalDateTime.now();
    }
}
