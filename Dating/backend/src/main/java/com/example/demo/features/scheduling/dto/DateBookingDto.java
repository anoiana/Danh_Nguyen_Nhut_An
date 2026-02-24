package com.example.demo.features.scheduling.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class DateBookingDto {
    private Long id;
    private Long requesterId;
    private String requesterName;
    private Long recipientId;
    private String recipientName;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String status;
    private String venue;
    private Boolean requesterConfirmed;
    private Boolean recipientConfirmed;
    private Boolean requesterAttended;
    private Boolean recipientAttended;
    private Boolean requesterWantsContact;
    private Boolean recipientWantsContact;
    private Boolean contactExchanged;
}
