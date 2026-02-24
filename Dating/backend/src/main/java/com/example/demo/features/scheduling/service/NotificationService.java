package com.example.demo.features.scheduling.service;

import com.example.demo.features.scheduling.dto.SchedulingNotification;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final SimpMessagingTemplate messagingTemplate;

    public void broadcastSchedulingUpdate(Long userId, SchedulingNotification notification) {
        messagingTemplate.convertAndSend("/topic/scheduling/" + userId, notification);
    }

    public void broadcastMatchUpdate(Long userId, Map<String, Object> notification) {
        messagingTemplate.convertAndSend("/topic/matches/" + userId, notification);
    }
}
