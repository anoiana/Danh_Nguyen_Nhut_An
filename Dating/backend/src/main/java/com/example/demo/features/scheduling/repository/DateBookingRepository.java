package com.example.demo.features.scheduling.repository;

import com.example.demo.features.scheduling.entity.DateBooking;
import com.example.demo.features.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface DateBookingRepository extends JpaRepository<DateBooking, Long> {
        List<DateBooking> findByRecipientAndStatus(User recipient, String status);

        List<DateBooking> findByRequesterOrRecipient(User requester, User recipient);

        @org.springframework.data.jpa.repository.Query("SELECT d FROM DateBooking d WHERE " +
                        "(d.requester.id = :userId OR d.recipient.id = :userId) " +
                        "AND d.status IN ('PROPOSED', 'CONFIRMED', 'PENDING', 'ACCEPTED') " +
                        "AND ((d.startTime < :endTime AND d.endTime > :startTime))")
        List<DateBooking> findOverlappingBookings(
                        @org.springframework.data.repository.query.Param("userId") Long userId,
                        @org.springframework.data.repository.query.Param("startTime") java.time.LocalDateTime startTime,
                        @org.springframework.data.repository.query.Param("endTime") java.time.LocalDateTime endTime);

        @org.springframework.data.jpa.repository.Query("SELECT d FROM DateBooking d WHERE " +
                        "((d.requester.id = :u1Id AND d.recipient.id = :u2Id) OR (d.requester.id = :u2Id AND d.recipient.id = :u1Id)) "
                        +
                        "AND d.status = 'CONFIRMED' ORDER BY d.startTime DESC")
        List<DateBooking> findConfirmedBookingBetweenUsers(
                        @org.springframework.data.repository.query.Param("u1Id") Long u1Id,
                        @org.springframework.data.repository.query.Param("u2Id") Long u2Id);
}
