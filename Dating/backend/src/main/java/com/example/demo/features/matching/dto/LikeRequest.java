package com.example.demo.features.matching.dto;

import lombok.Data;

@Data
public class LikeRequest {
    private Long fromUserId;
    private Long toUserId;
}
