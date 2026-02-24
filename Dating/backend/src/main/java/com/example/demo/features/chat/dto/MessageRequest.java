package com.example.demo.features.chat.dto;

import lombok.Data;

@Data
public class MessageRequest {
    private Long senderId;
    private Long receiverId;
    private String content;
}
