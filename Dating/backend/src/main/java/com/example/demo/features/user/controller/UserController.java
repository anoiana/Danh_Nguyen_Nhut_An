package com.example.demo.features.user.controller;

import com.example.demo.features.user.dto.UserDto;
import com.example.demo.features.user.entity.User;
import com.example.demo.features.user.service.UserService;
import com.example.demo.features.user.service.DiscoveryService;
import com.example.demo.features.user.service.CloudinaryService;
import com.example.demo.features.scheduling.service.NotificationService;
import lombok.RequiredArgsConstructor;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

/**
 * API Endpoints for user profile management and discovery.
 */
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;
    private final DiscoveryService discoveryService;
    private final CloudinaryService cloudinaryService;
    private final NotificationService notificationService;

    /**
     * Handles profile image uploads to Cloudinary.
     */
    @PostMapping("/upload")
    public ResponseEntity<String> uploadImage(
            @RequestParam("file") org.springframework.web.multipart.MultipartFile file) {
        try {
            String url = cloudinaryService.uploadFile(file);
            return ResponseEntity.ok(url);
        } catch (java.io.IOException e) {
            throw new com.example.demo.infra.exception.BusinessLogicException("Image upload failed: " + e.getMessage());
        }
    }

    /**
     * Updates user profile metadata.
     */
    @PutMapping("/{id}")
    public ResponseEntity<UserDto> updateUser(@PathVariable Long id, @Valid @RequestBody UserDto userDto) {
        User user = userService.findByIdOrThrow(id);

        user.setName(userDto.getName());
        user.setAge(userDto.getAge());
        user.setGender(userDto.getGender());
        user.setBio(userDto.getBio());
        user.setAvatarUrl(userDto.getAvatarUrl());
        user.setInterests(userDto.getInterests());
        user.setPhotos(userDto.getPhotos());
        user.setLatitude(userDto.getLatitude());
        user.setLongitude(userDto.getLongitude());

        User updated = userService.save(user);
        UserDto result = mapToDto(updated);

        // Broadcast to all users in the feed if the profile is "ready" (has photos)
        if (result.getPhotos() != null && !result.getPhotos().isEmpty()) {
            notificationService.broadcastNewUser(result);
        }

        return ResponseEntity.ok(result);
    }

    /**
     * Fetches details for a specific user profile.
     */
    @GetMapping("/{id}")
    public ResponseEntity<UserDto> getUser(@PathVariable Long id) {
        User user = userService.findByIdOrThrow(id);
        return ResponseEntity.ok(mapToDto(user));
    }

    /**
     * Generates a curative feed for the user based on preferences and daily
     * discovery logic.
     */
    @GetMapping("/feed")
    public ResponseEntity<List<UserDto>> getFeed(
            @RequestParam Long userId,
            @RequestParam(required = false) Integer minAge,
            @RequestParam(required = false) Integer maxAge,
            @RequestParam(required = false) String gender,
            @RequestParam(required = false) String interest) {

        // Validate user existence first.
        userService.findByIdOrThrow(userId);

        // Heavy lifting handled by DiscoveryService.
        List<UserDto> dtos = discoveryService.getFeed(userId, minAge, maxAge, gender, interest);
        return ResponseEntity.ok(dtos);
    }

    private UserDto mapToDto(User user) {
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
