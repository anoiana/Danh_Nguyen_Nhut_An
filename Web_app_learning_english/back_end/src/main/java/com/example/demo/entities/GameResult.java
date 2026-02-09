package com.example.demo.entities;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter
@Setter
@NoArgsConstructor
public class GameResult {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;
    private Long folderId;

    /**
     * Game type: "flashcard", "quiz", "write", "sentence"
     */
    private String gameType;

    private int correctCount;
    private int wrongCount;
    private String wrongAnswers;
}