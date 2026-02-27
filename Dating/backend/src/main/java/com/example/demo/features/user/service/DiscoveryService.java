package com.example.demo.features.user.service;

import com.example.demo.features.user.dto.UserDto;
import com.example.demo.features.user.entity.User;
import com.example.demo.features.matching.repository.LikeRepository;
import com.example.demo.features.user.repository.UserRepository;
import com.example.demo.infra.exception.ResourceNotFoundException;
import com.example.demo.infra.exception.UserPenalizedException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Service responsible for the "Breeze-style" user discovery flow.
 * Implements randomized curated feeds, daily quotas, and penalty restrictions.
 */
@Service
@RequiredArgsConstructor
public class DiscoveryService {

    private final UserRepository userRepository;
    private final LikeRepository likeRepository;

    /**
     * Generates a curated list of profiles for the current user.
     */
    public List<UserDto> getFeed(Long currentUserId, Integer minAge, Integer maxAge, String gender, String interest) {
        User currentUser = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + currentUserId));

        // 1. Anti-Flaker Logic: Block feed access if the user has a pending penalty
        if (currentUser.getPenalizedUntil() != null &&
                currentUser.getPenalizedUntil().isAfter(LocalDateTime.now())) {
            throw new UserPenalizedException(
                    "You are restricted from swiping until " + currentUser.getPenalizedUntil());
        }

        // 2. Curated Quota Logic: 7 new profiles per day
        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        long interactionsToday = likeRepository.countInteractionsToday(currentUserId, startOfDay);
        int quotaRemaining = (int) Math.max(0, 7 - interactionsToday);

        if (quotaRemaining <= 0) {
            return Collections.emptyList();
        }

        List<User> allUsers = userRepository.findAll();
        List<Long> interactedUserIds = likeRepository.findLikedUserIds(currentUserId);
        Set<Long> excludedIds = new HashSet<>(interactedUserIds);

        List<UserDto> filteredUsers = allUsers.stream()
                .filter(u -> !u.getId().equals(currentUserId))
                .filter(u -> !excludedIds.contains(u.getId()))
                .filter(u -> {
                    if (minAge != null && u.getAge() != null && u.getAge() < minAge)
                        return false;
                    if (maxAge != null && u.getAge() != null && u.getAge() > maxAge)
                        return false;

                    if (gender != null && !gender.isEmpty() && !gender.equalsIgnoreCase("All")) {
                        if (u.getGender() == null || !u.getGender().equalsIgnoreCase(gender))
                            return false;
                    }

                    if (interest != null && !interest.isEmpty()) {
                        if (u.getInterests() == null
                                || !u.getInterests().toLowerCase().contains(interest.toLowerCase()))
                            return false;
                    }
                    return true;
                })
                .map(this::convertToDto)
                .collect(Collectors.toList());

        // 3. Randomization
        Collections.shuffle(filteredUsers);

        return filteredUsers.stream()
                .limit(quotaRemaining)
                .collect(Collectors.toList());
    }

    private UserDto convertToDto(User user) {
        UserDto dto = new UserDto();
        dto.setId(user.getId());
        dto.setName(user.getName());
        dto.setEmail(user.getEmail());
        dto.setAge(user.getAge());
        dto.setGender(user.getGender());
        dto.setBio(user.getBio());
        dto.setAvatarUrl(user.getAvatarUrl());
        dto.setInterests(user.getInterests());
        dto.setPhotos(user.getPhotos());
        dto.setLatitude(user.getLatitude());
        dto.setLongitude(user.getLongitude());
        return dto;
    }
}
