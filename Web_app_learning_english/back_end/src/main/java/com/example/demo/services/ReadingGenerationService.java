// src/main/java/com/example/demo/services/ReadingGenerationService.java
package com.example.demo.services;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import okhttp3.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.List;
import java.util.concurrent.TimeUnit;

@Service
public class ReadingGenerationService {

  @Value("${groq.api.key}")
  private String groqApiKey;

  // Groq API endpoint - sử dụng llama-3.3-70b-versatile (model mạnh, miễn phí,
  // quota cao)
  private static final String GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions";
  private static final String MODEL = "llama-3.3-70b-versatile";

  private final OkHttpClient client = new OkHttpClient.Builder()
      .connectTimeout(30, TimeUnit.SECONDS)
      .writeTimeout(30, TimeUnit.SECONDS)
      .readTimeout(60, TimeUnit.SECONDS)
      .build();

  // DTO chứa kết quả
  public record ReadingContent(String story, JsonNode questions) {
  }

  /**
   * Phương thức chính để tạo bài đọc sử dụng Groq API.
   */
  public ReadingContent generateReadingPassage(List<String> vocabulary, int level, String topic) throws IOException {
    String prompt = createPrompt(vocabulary, level, topic);
    ObjectMapper objectMapper = new ObjectMapper();

    // Tạo payload cho Groq API (OpenAI format)
    ObjectNode payload = objectMapper.createObjectNode();
    payload.put("model", MODEL);
    payload.put("temperature", 0.7);
    payload.put("max_tokens", 2048);

    // Groq format: messages array with role and content
    ArrayNode messages = payload.putArray("messages");
    ObjectNode systemMessage = messages.addObject();
    systemMessage.put("role", "system");
    systemMessage.put("content",
        "You are a helpful AI assistant that generates English learning materials. Always respond with valid JSON only, no markdown formatting.");

    ObjectNode userMessage = messages.addObject();
    userMessage.put("role", "user");
    userMessage.put("content", prompt);

    // Response format để yêu cầu JSON
    ObjectNode responseFormat = payload.putObject("response_format");
    responseFormat.put("type", "json_object");

    String jsonPayload = objectMapper.writeValueAsString(payload);
    RequestBody body = RequestBody.create(jsonPayload, MediaType.get("application/json; charset=utf-8"));

    Request request = new Request.Builder()
        .url(GROQ_API_URL)
        .header("Authorization", "Bearer " + groqApiKey)
        .header("Content-Type", "application/json")
        .post(body)
        .build();

    // Thêm cơ chế thử lại để tăng độ tin cậy
    int maxRetries = 2;
    for (int i = 0; i < maxRetries; i++) {
      try (Response response = client.newCall(request).execute()) {
        String responseBody = response.body().string();

        if (!response.isSuccessful()) {
          System.err.println("Groq Error Response Body (Attempt " + (i + 1) + "): " + responseBody);
          if (i == maxRetries - 1) {
            throw new IOException(
                "Unexpected code from Groq after " + maxRetries + " attempts. Response: " + response);
          }
          continue;
        }

        System.out.println("Groq API Response: " + responseBody);

        JsonNode rootNode = objectMapper.readTree(responseBody);

        // Parse Groq response format: choices[0].message.content
        JsonNode choices = rootNode.path("choices");
        if (choices.isMissingNode() || choices.isEmpty()) {
          throw new IOException("Groq response missing 'choices': " + responseBody);
        }

        String contentString = choices.get(0)
            .path("message")
            .path("content")
            .asText();

        // Parse JSON từ response text
        JsonNode contentJson = objectMapper.readTree(contentString);

        return new ReadingContent(contentJson.path("story").asText(), contentJson.path("questions"));

      } catch (Exception e) {
        System.err.println("Error on attempt " + (i + 1) + ": " + e.getMessage());
        if (i == maxRetries - 1) {
          throw new IOException("Failed to generate and parse content after " + maxRetries + " attempts.", e);
        }
      }
    }
    throw new IOException("Failed to generate content after all retries.");
  }

  private String createPrompt(List<String> vocabulary, int level, String topic) {
    String difficultyDescription;
    switch (level) {
      case 1:
        difficultyDescription = "at a simple A2 (Elementary) English level";
        break;
      case 2:
        difficultyDescription = "at a B1 (Intermediate) English level";
        break;
      case 3:
        difficultyDescription = "at a B2 (Upper-Intermediate) English level";
        break;
      case 4:
        difficultyDescription = "at a C1 (Advanced) English level";
        break;
      case 5:
        difficultyDescription = "at a C2 (Proficient) English level";
        break;
      default:
        difficultyDescription = "at a B1 (Intermediate) English level";
    }

    String vocabList = String.join(", ", vocabulary);

    return String.format(
        """
            You are a helpful AI assistant that generates English learning materials.
            Your task is to create a short story and 5 multiple-choice questions based on it.

            **CRITICAL INSTRUCTIONS:**
            1.  Your ENTIRE response MUST be a single, valid JSON object.
            2.  Do NOT include any text, explanation, or markdown formatting (like ```json) before or after the JSON object.
            3.  The JSON structure MUST EXACTLY match the format specified in the "PERFECT RESPONSE EXAMPLE" below.

            **CONTENT CONSTRAINTS:**
            -   **Topic:** The story must be about "%s".
            -   **Vocabulary:** The story must naturally include these words: %s.
            -   **Difficulty:** The story and questions must be written %s.
            -   **Questions:** Create exactly 5 multiple-choice questions. Each question must have exactly 4 options. The "answer" field must be the full text of the correct option.

            **PERFECT RESPONSE EXAMPLE (Follow this structure precisely):**
            {
              "story": "A sample story about a brave cat who loved to explore the mysterious, old house. The cat was very curious and often found hidden treasures.",
              "questions": [
                {
                  "question": "What were the cat's main personality traits mentioned in the story?",
                  "options": [
                    "Shy and timid",
                    "Brave and curious",
                    "Lazy and sleepy",
                    "An and Bin"
                  ],
                  "answer": "Brave and curious"
                },
                {
                  "question": "Where did the cat love to explore?",
                  "options": [
                    "The sunny garden",
                    "The mysterious, old house",
                    "The busy city streets",
                    "The house"
                  ],
                  "answer": "The mysterious, old house"
                },
                {
                  "question": "What did the cat often find during its explorations?",
                  "options": [
                    "Other friendly cats",
                    "Bowls of milk",
                    "Hidden treasures",
                    "Hidden toy"
                  ],
                  "answer": "Hidden treasures"
                }
              ]
            }

            Now, generate the content based on all the constraints.
            """,
        topic, vocabList, difficultyDescription);
  }
}
