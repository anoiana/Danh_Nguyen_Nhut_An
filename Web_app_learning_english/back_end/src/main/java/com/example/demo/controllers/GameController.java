package com.example.demo.controllers;

import com.example.demo.entities.dto.GameDTO;
import com.example.demo.entities.dto.VocabularyDTO;
import com.example.demo.services.GameService;
import com.example.demo.services.GrammarService;
import com.example.demo.services.AiGrammarService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/game")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class GameController {

    @Autowired
    private GameService gameService;

    @Autowired
    private GrammarService grammarService;

    @PostMapping("/generate-listening")
    public ResponseEntity<?> generateListening(@RequestBody GameDTO.ListeningRequestDTO request) {
        try {
            GameDTO.ListeningResponseDTO response = gameService.generateListening(request);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            String message = e.getMessage();
            if (message.contains("Cần ít nhất")) {
                return ResponseEntity.badRequest().body(message);
            }
            if (message.contains("Invalid argument")) {
                return ResponseEntity.badRequest().body(message);
            }
            // For generic errors, or specific ones identified by message
            System.err.println("Error in generate-listening: " + message);
            return ResponseEntity.internalServerError().body(message);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().body("Dịch vụ AI hiện đang gặp sự cố. Vui lòng thử lại sau.");
        }
    }

    @PostMapping("/generate-reading")
    public ResponseEntity<?> generateReading(@RequestBody GameDTO.ReadingRequestDTO request) {
        try {
            GameDTO.ReadingResponseDTO response = gameService.generateReading(request);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            if (e.getMessage().equals("Thư mục này không có từ vựng nào.")) {
                return ResponseEntity.badRequest().body(e.getMessage());
            }
            System.err.println("Error in generate-reading: " + e.getMessage());
            return ResponseEntity.internalServerError().body(e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().body("Dịch vụ AI hiện đang gặp sự cố. Vui lòng thử lại sau.");
        }
    }

    @PostMapping("/start")
    public ResponseEntity<?> startGame(@RequestBody GameDTO.GameStartRequestDTO request) {
        try {
            Object session = gameService.startGame(request);
            return ResponseEntity.ok(session);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @PostMapping("/retry-wrong")
    public ResponseEntity<?> retryWrongAnswers(@RequestBody VocabularyDTO.GameRetryRequestDTO request) {
        try {
            Object session = gameService.retryWrongAnswers(request);
            return ResponseEntity.ok(session);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }

    @PostMapping("/check-sentence")
    public ResponseEntity<?> checkWritingSentence(@RequestBody GameDTO.SentenceCheckRequestDTO request) {
        try {
            // Use GrammarService to analyze the sentence
            AiGrammarService.GrammarAnalysisResult analysisResult = grammarService.analyze(request.userAnswer());

            boolean isCorrect = analysisResult.isCompleteSentence()
                    && (analysisResult.errors() == null || analysisResult.errors().isEmpty());
            String corrected = analysisResult.correctedSentence();
            String feedback;

            // Combine errors into feedback
            if (analysisResult.errors() != null && !analysisResult.errors().isEmpty()) {
                feedback = "Errors: " + String.join("; ", analysisResult.errors());
            } else if (!analysisResult.isCompleteSentence()) {
                feedback = "Sentence is incomplete.";
            } else {
                feedback = "Sentence is grammatically correct and complete.";
            }

            GameDTO.SentenceCheckResponseDTO response = new GameDTO.SentenceCheckResponseDTO(isCorrect, feedback,
                    corrected);

            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }
}