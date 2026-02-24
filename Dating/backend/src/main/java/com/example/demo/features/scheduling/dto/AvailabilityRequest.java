package com.example.demo.features.scheduling.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class AvailabilityRequest {
    private Long userId;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
}
