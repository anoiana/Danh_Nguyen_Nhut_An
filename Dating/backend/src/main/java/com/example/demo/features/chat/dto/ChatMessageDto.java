package com.example.demo.features.chat.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class ChatMessageDto {
    private Long id;
    private Long senderId;
    private String senderName;
    private Long receiverId;
    private String receiverName;
    private String content;
    private LocalDateTime sentAt;
}
