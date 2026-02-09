package com.example.demo.services;

import com.example.demo.entities.GameResult;
import com.example.demo.entities.dto.GameDTO;
import com.example.demo.repositories.GameResultRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class GameResultService {

    @Autowired
    private GameResultRepository gameResultRepository;

    /**
     * Updates an existing game result with new scores and wrong answers.
     *
     * @param id        The ID of the game result to update.
     * @param resultDTO The DTO containing the new scores and wrong answers.
     * @return The updated GameResult entity.
     * @throws RuntimeException if the game result is not found.
     */
    public GameResult updateGameResult(Long id, GameDTO.GameResultUpdateDTO resultDTO) {
        GameResult existing = gameResultRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Game result not found"));
        existing.setCorrectCount(resultDTO.correctCount());
        existing.setWrongCount(resultDTO.wrongCount());
        existing.setWrongAnswers(resultDTO.wrongAnswers());
        return gameResultRepository.save(existing);
    }

    /**
     * Retrieves all game results for a specific user where there are wrong answers.
     *
     * @param userId The ID of the user.
     * @return A list of GameResult entities with wrong answers.
     */
    public List<GameResult> getWrongAnswers(Long userId) {
        return gameResultRepository.findAll().stream()
                .filter(r -> r.getUserId().equals(userId) && r.getWrongCount() > 0)
                .collect(Collectors.toList());
    }
}
