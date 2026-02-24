package com.example.demo.features.user.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Represents a user profile in the dating platform.
 * Includes basic identity info and preference metadata for discovery.
 */
@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false)
    private String name;

    private Integer age;

    private String gender;

    @Column(columnDefinition = "TEXT")
    private String bio;

    private String avatarUrl;

    @Column(columnDefinition = "TEXT")
    private String interests;

    // A comma-separated list of image URLs hosted on Cloudinary.
    @Column(columnDefinition = "TEXT")
    private String photos;

    // Anti-flaker protection: The user is blocked from the discovery feed
    // until this timestamp if they cancel confirmed dates.
    private java.time.LocalDateTime penalizedUntil;
}
