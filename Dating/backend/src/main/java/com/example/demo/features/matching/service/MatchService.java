package com.example.demo.features.matching.service;

import com.example.demo.features.matching.entity.Match;
import com.example.demo.features.user.entity.User;
import com.example.demo.features.matching.repository.MatchRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Service managing user matches (Mutual Likes).
 * Ensures database integrity by normalizing user pairings.
 */
@Service
@RequiredArgsConstructor
public class MatchService {

    private final MatchRepository matchRepository;

    public List<Match> getMatchesForUser(User user) {
        return matchRepository.findByUser(user);
    }

    public List<Match> getWaitingMatchesForUser(User user) {
        return matchRepository.findWaitingForScheduleByUser(user);
    }

    /**
     * Creates an official Match record between two users.
     * Implements an "Ordering Constraint" to prevent duplicate rows
     * (e.g., prevents having both A matches B AND B matches A).
     */
    @Transactional
    public Match createMatch(User u1, User u2) {
        if (u1.getId().equals(u2.getId())) {
            throw new IllegalArgumentException("Cannot match user with themselves");
        }

        User user1;
        User user2;

        // Symmetry Normalization: Always store the smaller ID in 'user1'.
        // This ensures findBetweenUsers(A, B) and findBetweenUsers(B, A)
        // always target the same database row.
        if (u1.getId() < u2.getId()) {
            user1 = u1;
            user2 = u2;
        } else {
            user1 = u2;
            user2 = u1;
        }

        Match match = new Match();
        match.setUser1(user1);
        match.setUser2(user2);

        return matchRepository.save(match);
    }

    public Match getMatchBetweenUsers(User u1, User u2) {
        return matchRepository.findBetweenUsers(u1, u2);
    }

    /**
     * Updates the status of a match (e.g., from WAITING to SCHEDULED).
     */
    @Transactional
    public void updateMatchStatus(User u1, User u2, Match.Status status) {
        Match match = getMatchBetweenUsers(u1, u2);
        if (match != null) {
            match.setStatus(status);
            matchRepository.save(match);
        }
    }
}
