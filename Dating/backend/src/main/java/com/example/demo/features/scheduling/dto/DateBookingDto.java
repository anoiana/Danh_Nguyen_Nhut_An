package com.example.demo.features.scheduling.dto;

import lombok.Data;
import java.time.LocalDateTime;
import com.fasterxml.jackson.annotation.JsonFormat;

@Data
public class DateBookingDto {
    private Long id;
    private Long requesterId;
    private String requesterName;
    private Long recipientId;
    private String recipientName;

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss'Z'")
    private LocalDateTime startTime;

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss'Z'")
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
    private String requesterAvatar;
    private String recipientAvatar;
    private String requesterEmail;
    private String recipientEmail;
}
