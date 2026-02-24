package com.example.demo.features.matching.controller;

import com.example.demo.features.matching.dto.LikeRequest;
import com.example.demo.features.matching.service.LikeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * API Endpoints for user interactions in the discovery feed.
 * Processes Likes and Skips to drive the matching logic.
 */
@RestController
@RequestMapping("/api/likes")
@RequiredArgsConstructor
public class LikeController {

    private final LikeService likeService;

    /**
     * Processes a "Like" action.
     * If reciprocity is detected, returns a specific message to trigger UI
     * celebration.
     */
    @PostMapping
    public ResponseEntity<String> likeUser(@RequestBody LikeRequest request) {
        boolean isMatch = likeService.processLike(request.getFromUserId(), request.getToUserId());
        if (isMatch) {
            // UI Strategy: Returning a specific string allows the frontend to trigger
            // celebration animations (e.g., MatchPopup).
            return ResponseEntity.ok("It's a Match! You can now start dating.");
        } else {
            return ResponseEntity.ok("Like sent successfully.");
        }
    }

    /**
     * Processes a "Skip" action.
     * Users who are skipped will no longer appear in the daily feed.
     */
    @PostMapping("/skip")
    public ResponseEntity<String> skipUser(@RequestBody LikeRequest request) {
        likeService.processSkip(request.getFromUserId(), request.getToUserId());
        return ResponseEntity.ok("User skipped.");
    }
}
