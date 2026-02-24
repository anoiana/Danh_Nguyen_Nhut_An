package com.example.demo.features.matching.controller;

import com.example.demo.features.matching.dto.MatchDto;
import com.example.demo.features.matching.entity.Match;
import com.example.demo.features.matching.service.MatchService;
import com.example.demo.features.user.entity.User;
import com.example.demo.features.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

/**
 * API Endpoints for managing and retrieving user matches.
 */
@RestController
@RequestMapping("/api/matches")
@RequiredArgsConstructor
public class MatchController {

    private final MatchService matchService;
    private final UserService userService;

    /**
     * Retrieves all active matches for a user (Mutual Likes).
     */
    @GetMapping
    public ResponseEntity<List<MatchDto>> getMatches(@RequestParam Long userId) {
        User user = userService.findByIdOrThrow(userId);
        List<MatchDto> dtos = matchService.getMatchesForUser(user)
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Retrieves matches that are waiting for scheduling.
     */
    @GetMapping("/waiting")
    public ResponseEntity<List<MatchDto>> getWaitingMatches(@RequestParam Long userId) {
        User user = userService.findByIdOrThrow(userId);
        List<MatchDto> dtos = matchService.getWaitingMatchesForUser(user)
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Checks the current coordination status between two users.
     */
    @GetMapping("/status")
    public ResponseEntity<MatchDto> getMatchStatus(
            @RequestParam Long u1Id,
            @RequestParam Long u2Id) {
        User u1 = userService.findByIdOrThrow(u1Id);
        User u2 = userService.findByIdOrThrow(u2Id);
        Match match = matchService.getMatchBetweenUsers(u1, u2);
        if (match != null) {
            return ResponseEntity.ok(convertToDto(match));
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    private MatchDto convertToDto(Match entity) {
        MatchDto dto = new MatchDto();
        dto.setId(entity.getId());
        dto.setUser1Id(entity.getUser1().getId());
        dto.setUser1Name(entity.getUser1().getName());
        dto.setUser1Avatar(entity.getUser1().getAvatarUrl());
        dto.setUser2Id(entity.getUser2().getId());
        dto.setUser2Name(entity.getUser2().getName());
        dto.setUser2Avatar(entity.getUser2().getAvatarUrl());
        dto.setStatus(entity.getStatus());
        dto.setCreatedAt(entity.getCreatedAt());
        return dto;
    }
}
