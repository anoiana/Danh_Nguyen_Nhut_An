package com.example.demo.features.chat.controller;

import com.example.demo.features.chat.dto.ChatMessageDto;
import com.example.demo.features.chat.dto.MessageRequest;
import com.example.demo.features.chat.entity.ChatMessage;
import com.example.demo.features.chat.repository.ChatMessageRepository;
import com.example.demo.features.scheduling.service.ActivityService;
import com.example.demo.features.scheduling.service.AvailabilityService;
import com.example.demo.features.user.entity.User;
import com.example.demo.features.user.service.UserService;
import com.example.demo.infra.exception.BusinessLogicException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Controller managing real-time chat between users.
 * Enforces strict locking logic to ensure users only chat near their date time.
 */
@RestController
@RequestMapping("/api/messages")
@RequiredArgsConstructor
public class ChatController {

        private final ChatMessageRepository messageRepository;
        private final UserService userService;
        private final ActivityService activityService;
        private final AvailabilityService availabilityService;
        private final SimpMessagingTemplate messagingTemplate;

        /**
         * Sends a message if the chat window is currently unlocked.
         * Broadcasts via WebSockets for real-time delivery.
         */
        @PostMapping
        public ResponseEntity<ChatMessageDto> sendMessage(@RequestBody MessageRequest request) {
                // Rule: No chatting unless a confirmed date is imminent (or very recent).
                if (!availabilityService.canChat(request.getSenderId(), request.getReceiverId())) {
                        throw new BusinessLogicException("Trò chuyện chỉ mở khóa 4 tiếng trước giờ hẹn! 🔒");
                }

                User sender = userService.findByIdOrThrow(request.getSenderId());
                User receiver = userService.findByIdOrThrow(request.getReceiverId());

                ChatMessage message = new ChatMessage(sender, receiver, request.getContent());
                ChatMessage savedMessage = messageRepository.save(message);

                activityService.logActivity(receiver,
                                sender.getName() + " vừa nhắn cho bạn: \"" + request.getContent() + "\"",
                                "MESSAGE_NEW");

                // Real-time synchronization for both parties.
                ChatMessageDto dto = convertToDto(savedMessage);
                messagingTemplate.convertAndSend("/topic/messages/" + receiver.getId(), dto);
                messagingTemplate.convertAndSend("/topic/messages/" + sender.getId(), dto);

                return ResponseEntity.ok(dto);
        }

        /**
         * Retrieves the message history between two users.
         */
        @GetMapping("/history")
        public ResponseEntity<List<ChatMessageDto>> getChatHistory(
                        @RequestParam Long u1Id,
                        @RequestParam Long u2Id) {
                if (!availabilityService.canChat(u1Id, u2Id)) {
                        throw new BusinessLogicException("Trò chuyện chỉ mở khóa 4 tiếng trước giờ hẹn! 🔒");
                }

                User u1 = userService.findByIdOrThrow(u1Id);
                User u2 = userService.findByIdOrThrow(u2Id);

                List<ChatMessageDto> history = messageRepository.findChatHistory(u1, u2)
                                .stream()
                                .map(this::convertToDto)
                                .collect(Collectors.toList());

                return ResponseEntity.ok(history);
        }

        private ChatMessageDto convertToDto(ChatMessage entity) {
                ChatMessageDto dto = new ChatMessageDto();
                dto.setId(entity.getId());
                dto.setSenderId(entity.getSender().getId());
                dto.setSenderName(entity.getSender().getName());
                dto.setReceiverId(entity.getReceiver().getId());
                dto.setReceiverName(entity.getReceiver().getName());
                dto.setContent(entity.getContent());
                dto.setSentAt(entity.getSentAt());
                return dto;
        }
}
