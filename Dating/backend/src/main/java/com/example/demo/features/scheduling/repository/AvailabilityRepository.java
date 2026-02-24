package com.example.demo.features.scheduling.repository;

import com.example.demo.features.scheduling.entity.Availability;
import com.example.demo.features.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AvailabilityRepository extends JpaRepository<Availability, Long> {
    List<Availability> findByUser(User user);

    @org.springframework.data.jpa.repository.Query("SELECT a FROM Availability a WHERE " +
            "a.user.id = :userId AND " +
            "((a.startTime < :endTime AND a.endTime > :startTime))")
    List<Availability> findOverlappingAvailabilities(
            @org.springframework.data.repository.query.Param("userId") Long userId,
            @org.springframework.data.repository.query.Param("startTime") java.time.LocalDateTime startTime,
            @org.springframework.data.repository.query.Param("endTime") java.time.LocalDateTime endTime);
}
