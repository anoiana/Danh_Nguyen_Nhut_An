package com.example.demo.features.scheduling.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class SchedulingNotification {
    private String type; // MATCH_STATUS_UPDATE, BOOKING_PROPOSED, BOOKING_CONFIRMED, USER_CONFIRMED
    private Object data;
    private String message;
}
