package com.example.demo.features.matching.dto;

import com.example.demo.features.matching.entity.Match;
import lombok.Data;
import java.time.LocalDateTime;

@Data
public class MatchDto {
    private Long id;
    private Long user1Id;
    private String user1Name;
    private String user1Avatar;
    private String user1Photos;
    private Long user2Id;
    private String user2Name;
    private String user2Avatar;
    private String user2Photos;
    private Match.Status status;
    private LocalDateTime createdAt;
}
