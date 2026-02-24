package com.example.demo.features.payment.entity;

import com.example.demo.features.scheduling.entity.DateBooking;
import com.example.demo.features.user.entity.User;
import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

/**
 * Represents a discrete payment transaction for a date token.
 */
@Entity
@Table(name = "payment_transactions")
@Data
@NoArgsConstructor
public class PaymentTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "booking_id", nullable = false)
    private DateBooking booking;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private Long amount;

    // The unique reference id sent to VNPay
    @Column(nullable = false, unique = true)
    private String txnRef;

    // Status: PENDING, SUCCESS, FAILED
    @Column(nullable = false)
    private String status;

    private LocalDateTime createdAt = LocalDateTime.now();
}
