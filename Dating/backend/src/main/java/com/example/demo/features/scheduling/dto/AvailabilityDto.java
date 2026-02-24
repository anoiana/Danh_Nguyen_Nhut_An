package com.example.demo.features.scheduling.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class AvailabilityDto {
    private Long id;
    private Long userId;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
}
