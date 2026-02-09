package com.example.demo.controllers;

import com.example.demo.entities.GameResult;
import com.example.demo.entities.dto.GameDTO;
import com.example.demo.services.GameResultService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/game-results")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class GameResultController {

    @Autowired
    private GameResultService gameResultService;

    @PutMapping("/{id}")
    public ResponseEntity<?> updateGameResult(@PathVariable Long id,
            @RequestBody GameDTO.GameResultUpdateDTO resultDTO) {
        try {
            GameResult updatedResult = gameResultService.updateGameResult(id, resultDTO);
            return ResponseEntity.ok(updatedResult);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/wrong/{userId}")
    public ResponseEntity<List<GameResult>> getWrongAnswers(@PathVariable Long userId) {
        List<GameResult> results = gameResultService.getWrongAnswers(userId);
        return ResponseEntity.ok(results);
    }
}