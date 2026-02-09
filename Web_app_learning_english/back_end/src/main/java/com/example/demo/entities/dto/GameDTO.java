package com.example.demo.entities.dto;

import com.example.demo.entities.Meaning;
import com.fasterxml.jackson.databind.JsonNode;

import java.util.List;

public class GameDTO {
        public record ListeningRequestDTO(Long folderId, int level, String topic, String gameSubType) {
        }

        public record ListeningContentDTO(String transcript, JsonNode mcq, JsonNode fitb) {
        }

        public record ListeningResponseDTO(String transcript, JsonNode mcq, JsonNode fitb) {
        }

        public record GameResultUpdateDTO(int correctCount, int wrongCount, String wrongAnswers) {
        }

        public record ReadingRequestDTO(Long folderId, int level, String topic) {
        }

        public record ReadingResponseDTO(String story, com.fasterxml.jackson.databind.JsonNode questions) {
        }

        public record GameStartRequestDTO(Long userId, Long folderId, String gameType, String subType) {
        }

        public record SentenceCheckRequestDTO(Integer vocabularyId, String userAnswer) {
        }

        public record GameSessionDTO(Long gameResultId, List<VocabularyDetailDTO> vocabularies) {
        }

        public record QuizSessionDTO(Long gameResultId, List<QuizQuestionDTO> questions) {
        }

        public record ReverseQuizSessionDTO(Long gameResultId, List<ReverseQuizQuestionDTO> questions) {
        }

        public record SentenceCheckResponseDTO(boolean isCorrect, String feedback, String correctedSentence) {
        }

        public record QuizQuestionDTO(
                        Long vocabularyId,
                        String word,
                        String phoneticText,
                        String partOfSpeech,
                        List<String> options,
                        String correctAnswer,
                        String userImageBase64) {
        }

        public record ReverseQuizQuestionDTO(
                        Long vocabularyId,
                        String userDefinedMeaning,
                        String phoneticText,
                        String partOfSpeech,
                        List<String> options,
                        String correctAnswer,
                        String userImageBase64) {
        }

        public record VocabularyDetailDTO(
                        Long id,
                        String word,
                        String phoneticText,
                        String audioUrl,
                        String userDefinedMeaning,
                        String userImageBase64,
                        List<Meaning> meanings) {
        }
}
