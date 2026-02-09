package com.example.demo.services;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import okhttp3.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.TimeUnit;

@Service
public class AiGrammarService {

    @Value("${groq.api.key}")
    private String groqApiKey;

    private static final String GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions";
    private static final String MODEL = "llama-3.3-70b-versatile";

    private final OkHttpClient client = new OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .build();

    public record GrammarAnalysisResult(boolean isCompleteSentence, List<String> errors, String correctedSentence) {
    }

    /**
     * Analyzes a sentence for completeness and grammar mistakes using AI.
     *
     * @param sentence The sentence to check.
     * @return An AnalysisResult containing completeness status, list of errors, and
     *         corrected sentence.
     * @throws IOException If the API interaction fails.
     */
    public GrammarAnalysisResult analyzeSentence(String sentence) throws IOException {
        ObjectMapper objectMapper = new ObjectMapper();
        ObjectNode payload = objectMapper.createObjectNode();
        payload.put("model", MODEL);
        payload.put("temperature", 0.3);
        payload.put("max_tokens", 1024);

        ArrayNode messages = payload.putArray("messages");
        ObjectNode systemMessage = messages.addObject();
        systemMessage.put("role", "system");
        systemMessage.put("content", "You are an expert English grammar assistant. Check the provided text. " +
                "1. Determine if it is a complete English sentence (has subject and verb, makes sense mainly). " +
                "2. Identify any grammar or severe spelling mistakes. " +
                "3. Provide a corrected version of the sentence if there are errors. " +
                "Respond ONLY with a valid JSON object in this format: " +
                "{ \"isCompleteSentence\": boolean, \"errors\": [\"string error 1\", \"string error 2\"], \"correctedSentence\": \"string\" }. "
                +
                "If correct and complete, \"errors\" should be empty and \"correctedSentence\" should be null or the original sentence.");

        ObjectNode userMessage = messages.addObject();
        userMessage.put("role", "user");
        userMessage.put("content", "Analyze this text: \"" + sentence + "\"");

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

        try (Response response = client.newCall(request).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Unexpected code from Groq: " + response.code());
            }

            String responseBody = response.body().string();
            JsonNode rootNode = objectMapper.readTree(responseBody);
            JsonNode choices = rootNode.path("choices");
            if (choices.isEmpty()) {
                throw new IOException("Empty choices from AI response");
            }

            String contentString = choices.get(0).path("message").path("content").asText();
            JsonNode contentJson = objectMapper.readTree(contentString);

            boolean isComplete = contentJson.path("isCompleteSentence").asBoolean(false);
            List<String> errors = new java.util.ArrayList<>();
            JsonNode errorNode = contentJson.path("errors");
            if (errorNode.isArray()) {
                for (JsonNode error : errorNode) {
                    errors.add(error.asText());
                }
            }
            String correctedSentence = contentJson.has("correctedSentence")
                    && !contentJson.get("correctedSentence").isNull()
                            ? contentJson.get("correctedSentence").asText()
                            : null;

            return new GrammarAnalysisResult(isComplete, errors, correctedSentence);
        }
    }
}
