package com.example.demo.features.user.controller;

import com.example.demo.features.user.dto.UserDto;
import com.example.demo.features.user.entity.User;
import com.example.demo.features.user.service.UserService;
import com.example.demo.features.user.service.DiscoveryService;
import com.example.demo.features.user.service.CloudinaryService;
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

        User updated = userService.save(user);
        return ResponseEntity.ok(mapToDto(updated));
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
        return dto;
    }
}
