package com.example.demo.features.matching.service;

import com.example.demo.features.matching.entity.Like;
import com.example.demo.features.user.entity.User;
import com.example.demo.features.user.service.UserService;
import com.example.demo.features.matching.repository.LikeRepository;
import com.example.demo.features.scheduling.service.ActivityService;
import com.example.demo.infra.exception.ResourceNotFoundException;
import com.example.demo.features.scheduling.service.NotificationService;
import java.util.Map;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Service managing user interactions (Likes and Skips).
 * Handles the logic for detecting mutual likes and initiating the Match entity.
 */
@Service
@RequiredArgsConstructor
public class LikeService {

    private final LikeRepository likeRepository;
    private final UserService userService;
    private final MatchService matchService;
    private final ActivityService activityService;
    private final NotificationService notificationService;

    /**
     * Processes a "Like" action from one user to another.
     * 
     * @return true if a mutual match was created, false otherwise.
     */
    @Transactional
    public boolean processLike(Long fromUserId, Long toUserId) {
        User fromUser = userService.findById(fromUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + fromUserId));
        User toUser = userService.findById(toUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + toUserId));

        // 1. Persistence: Save the Like record to track history and prevent duplicate
        // likes.
        if (!likeRepository.existsByFromUserAndToUser(fromUser, toUser)) {
            Like like = new Like(fromUser, toUser, Like.Type.LIKE);
            likeRepository.save(like);
        }

        // 2. Reciprocity Check: If the 'toUser' had already liked 'fromUser', we have a
        // match.
        boolean isMutual = likeRepository.existsByFromUserAndToUserAndType(toUser, fromUser, Like.Type.LIKE);

        if (isMutual) {
            // Match Creation: Transition from mutual likes to an official Match entity.
            matchService.createMatch(fromUser, toUser);

            activityService.logActivity(fromUser, "You and " + toUser.getName() + " have matched! 💖", "MATCH");
            activityService.logActivity(toUser, "You and " + fromUser.getName() + " have matched! 💖", "MATCH");

            notificationService.broadcastMatchUpdate(fromUser.getId(), Map.of("type", "MATCH"));
            notificationService.broadcastMatchUpdate(toUser.getId(), Map.of("type", "MATCH"));

            return true;
        }

        return false;
    }

    /**
     * Processes a "Skip" action.
     * Ensures the skipped user does not appear in the discover feed again.
     */
    @Transactional
    public void processSkip(Long fromUserId, Long toUserId) {
        User fromUser = userService.findById(fromUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + fromUserId));
        User toUser = userService.findById(toUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + toUserId));

        if (!likeRepository.existsByFromUserAndToUser(fromUser, toUser)) {
            Like skip = new Like(fromUser, toUser, Like.Type.SKIP);
            likeRepository.save(skip);
        }
    }
}
