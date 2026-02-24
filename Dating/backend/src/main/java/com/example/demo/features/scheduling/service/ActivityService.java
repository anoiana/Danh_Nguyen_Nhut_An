package com.example.demo.features.scheduling.service;

import com.example.demo.features.scheduling.dto.ActivityDto;
import com.example.demo.features.scheduling.entity.Activity;
import com.example.demo.features.user.entity.User;
import com.example.demo.features.scheduling.repository.ActivityRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Service for managing user notifications and engagement logs.
 * Handles persistence and real-time broadcasting of in-app alerts.
 */
@Service
@RequiredArgsConstructor
public class ActivityService {

    private final ActivityRepository activityRepository;
    private final SimpMessagingTemplate messagingTemplate;

    /**
     * Records a new activity and pushes it immediately to the user's UI.
     */
    @Transactional
    public void logActivity(User user, String content, String type) {
        Activity activity = new Activity(user, content, type);
        Activity saved = activityRepository.save(activity);

        // Real-time Push via WebSocket
        messagingTemplate.convertAndSend("/topic/activities/" + user.getId(), convertToDto(saved));
    }

    public List<ActivityDto> getMyActivities(User user) {
        return activityRepository.findByUserOrderByCreatedAtDesc(user)
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    /**
     * Resets the unread count for the user's notification center.
     */
    @Transactional
    public void markAllAsRead(User user) {
        List<Activity> list = activityRepository.findByUserOrderByCreatedAtDesc(user);
        list.forEach(a -> a.setIsRead(true));
        activityRepository.saveAll(list);
    }

    private ActivityDto convertToDto(Activity entity) {
        ActivityDto dto = new ActivityDto();
        dto.setId(entity.getId());
        dto.setUserId(entity.getUser().getId());
        dto.setContent(entity.getContent());
        dto.setType(entity.getType());
        dto.setIsRead(entity.getIsRead());
        dto.setCreatedAt(entity.getCreatedAt());
        return dto;
    }
}
