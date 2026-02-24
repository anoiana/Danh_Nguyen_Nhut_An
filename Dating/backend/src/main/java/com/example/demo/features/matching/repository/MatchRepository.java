package com.example.demo.features.matching.repository;

import com.example.demo.features.matching.entity.Match;
import com.example.demo.features.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MatchRepository extends JpaRepository<Match, Long> {
    @Query("SELECT m FROM Match m WHERE m.user1 = :user OR m.user2 = :user")
    List<Match> findByUser(@Param("user") User user);

    @Query("SELECT m FROM Match m WHERE (m.user1 = :user OR m.user2 = :user) AND m.status = 'WAITING_FOR_SCHEDULE' ORDER BY m.createdAt DESC")
    List<Match> findWaitingForScheduleByUser(@Param("user") User user);

    @Query("SELECT m FROM Match m WHERE (m.user1 = :u1 AND m.user2 = :u2) OR (m.user1 = :u2 AND m.user2 = :u1)")
    Match findBetweenUsers(@Param("u1") User u1, @Param("u2") User u2);
}
