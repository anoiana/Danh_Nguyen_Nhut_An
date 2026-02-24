package com.example.demo.features.scheduling.controller;

import com.example.demo.features.user.entity.User;
import com.example.demo.features.scheduling.service.ActivityService;
import com.example.demo.features.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/activities")
@RequiredArgsConstructor
public class ActivityController {

    private final ActivityService activityService;
    private final UserService userService;

    @GetMapping
    public ResponseEntity<?> getMyActivities(@RequestParam Long userId) {
        User user = userService.findByIdOrThrow(userId);
        return ResponseEntity.ok(activityService.getMyActivities(user));
    }

    @PostMapping("/mark-read")
    public ResponseEntity<Void> markRead(@RequestParam Long userId) {
        User user = userService.findByIdOrThrow(userId);
        activityService.markAllAsRead(user);
        return ResponseEntity.ok().build();
    }
}
