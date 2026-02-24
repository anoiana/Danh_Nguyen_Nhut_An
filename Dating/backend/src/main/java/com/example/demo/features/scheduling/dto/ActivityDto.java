package com.example.demo.features.scheduling.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class ActivityDto {
    private Long id;
    private Long userId;
    private String content;
    private String type;
    private Boolean isRead;
    private LocalDateTime createdAt;
}
