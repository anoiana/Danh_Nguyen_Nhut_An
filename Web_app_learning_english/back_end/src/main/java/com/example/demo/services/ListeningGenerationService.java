package com.example.demo.services;

import com.example.demo.dto.GameDTO;
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
public class ListeningGenerationService {

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

    public GameDTO.ListeningContentDTO generateListeningTask(List<String> vocabulary, int level, String topic,
            String gameSubType) throws IOException {
        String prompt;

        // Chọn prompt phù hợp dựa trên loại game con (mcq hoặc fitb)
        if ("mcq".equalsIgnoreCase(gameSubType)) {
            prompt = createMcqPrompt(vocabulary, level, topic);
        } else if ("fitb".equalsIgnoreCase(gameSubType)) {
            prompt = createFitbPrompt(vocabulary, level, topic);
        } else {
            throw new IllegalArgumentException("Invalid gameSubType provided: " + gameSubType);
        }

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
                "You are a helpful AI assistant that creates English listening exercises. Always respond with valid JSON only, no markdown formatting.");

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

        try (Response response = client.newCall(request).execute()) {
            if (!response.isSuccessful()) {
                String errorBody = response.body() != null ? response.body().string() : "No response body";
                System.err.println("Groq API Error: " + response.code() + " - " + errorBody);
                throw new IOException("Unexpected code from Groq: " + response);
            }

            String responseBody = response.body().string();
            System.out.println("Groq API Response: " + responseBody);

            JsonNode rootNode = objectMapper.readTree(responseBody);

            // Parse Groq response format: choices[0].message.content
            JsonNode choices = rootNode.path("choices");
            if (choices.isMissingNode() || choices.isEmpty()) {
                throw new IOException("Groq response is missing 'choices' field: " + responseBody);
            }

            String contentString = choices.get(0)
                    .path("message")
                    .path("content")
                    .asText();

            JsonNode contentJson = objectMapper.readTree(contentString);

            // Trả về DTO với các trường có thể là null, tùy thuộc vào loại game
            return new GameDTO.ListeningContentDTO(
                    contentJson.path("transcript").asText(),
                    contentJson.path("mcq"),
                    contentJson.path("fitb"));
        }
    }

    private String createMcqPrompt(List<String> vocabulary, int level, String topic) {
        String difficulty;
        String questionDifficultySummary;
        switch (level) {
            case 1:
                difficulty = "simple (A2-B1 level), with common vocabulary and a slightly slow pace";
                questionDifficultySummary = "easy, focusing on specific, directly stated details.";
                break;
            case 2:
                difficulty = "intermediate (B2 level), with a good range of vocabulary and a natural pace";
                questionDifficultySummary = "of medium difficulty, mixing detail questions and simple inference.";
                break;
            case 3:
                difficulty = "advanced (C1-C2 level), with varied vocabulary and a faster pace";
                questionDifficultySummary = "challenging, testing understanding of main points and opinions.";
                break;
            default:
                difficulty = "intermediate (B2 level), at a natural speaking pace";
                questionDifficultySummary = "of medium difficulty";
        }
        String vocabList = String.join(", ", vocabulary);

        return String.format(
                """
                        You are an AI assistant creating an English listening exercise with multiple-choice questions.
                        Your entire response MUST be a single, valid JSON object, containing ONLY 'transcript' and 'mcq' keys.

                        **CONTEXT:**
                        -   Topic: A conversation about "%s".
                        -   Vocabulary: The conversation must include: %s.
                        -   Conversation Difficulty: %s.

                        **INSTRUCTIONS:**
                        1.  **Generate Transcript:** Write a conversation script (approx. 200-250 words) between two people.
                        2.  **Generate Multiple-Choice Questions (MCQ):**
                            -   Create **exactly 5 multiple-choice questions** based on the transcript.
                            -   The question difficulty must be: **%s**.
                            -   Questions should be arranged sequentially according to the conversation flow.

                        **PERFECT JSON RESPONSE EXAMPLE:**
                        {
                          "transcript": "Man: The new city library is impressive, isn't it?\\nWoman: It really is! The architecture is so modern. And they have a huge collection of digital books, which is very convenient.\\nMan: I agree. I was surprised by the number of community events they host too. I saw a flyer for a creative writing workshop next week.\\nWoman: Oh, that sounds interesting! I might sign up for that. A professional author is leading it.",
                          "mcq": [
                            { "question": "What feature of the library does the woman find convenient?", "options": ["The location", "The opening hours", "The digital book collection", "The coffee shop"], "answer": "The digital book collection" },
                            { "question": "What event did the man see advertised?", "options": ["A book club meeting", "A children's story time", "A creative writing workshop", "A technology class"], "answer": "A creative writing workshop" },
                            { "question": "Who is leading the workshop?", "options": ["A librarian", "A local teacher", "A university professor", "A professional author"], "answer": "A professional author" },
                            { "question": "What is the man's initial impression of the library?", "options": ["It is too small", "It is impressive", "It is crowded", "It is hard to find"], "answer": "It is impressive" },
                            { "question": "What is the general tone of the conversation?", "options": ["Negative and critical", "Positive and enthusiastic", "Neutral and informative", "Confused and questioning"], "answer": "Positive and enthusiastic" }
                          ]
                        }
                        """,
                topic, vocabList, difficulty, questionDifficultySummary);
    }

    private String createFitbPrompt(List<String> vocabulary, int level, String topic) {
        String difficulty;
        switch (level) {
            case 1:
                difficulty = "simple (A2-B1 level), with common vocabulary and a slightly slow pace";
                break;
            case 2:
                difficulty = "intermediate (B2 level), with a good range of vocabulary and a natural pace";
                break;
            case 3:
                difficulty = "advanced (C1-C2 level), with varied vocabulary and a faster pace";
                break;
            default:
                difficulty = "intermediate (B2 level), at a natural speaking pace";
        }
        String vocabList = String.join(", ", vocabulary);

        return String.format(
                """
                        You are an AI assistant creating an English listening exercise with a fill-in-the-blanks task.
                        Your entire response MUST be a single, valid JSON object, containing ONLY 'transcript' and 'fitb' keys.

                        **CONTEXT:**
                        -   Topic: A conversation about "%s".
                        -   Vocabulary: The conversation must include: %s.
                        -   Conversation Difficulty: %s.

                        **INSTRUCTIONS:**
                        1.  **Generate Transcript:** Write a conversation script (approx. 200-250 words) between two people.
                        2.  **Generate Fill-in-the-Blanks (FITB) Exercise:**
                            -   Take key sentences directly from the transcript.
                            -   Replace 5-7 important words with blanks like "____(1)____".
                            -   The blanks should be arranged sequentially according to the conversation flow.

                        **PERFECT JSON RESPONSE EXAMPLE:**
                        {
                          "transcript": "Man: I'm planning a trip to the mountains next month. I need to buy some new hiking equipment.\\nWoman: Oh, exciting! Durability is the most important factor to consider. You don't want your gear failing on a difficult trail.\\nMan: Exactly. I'm looking for a waterproof jacket and some sturdy boots. My old ones are completely worn out.\\nWoman: Good choice. Also, make sure to get a comfortable backpack. It makes a huge difference on long hikes.",
                          "fitb": {
                            "textWithBlanks": "The man is planning a trip to the ____(1)____ next month. He needs to buy new hiking ____(2)____. The woman says that ____(3)____ is the most important factor. The man is looking for a ____(4)____ jacket and sturdy boots. The woman advises him to get a ____(5)____ backpack.",
                            "answers": ["mountains", "equipment", "durability", "waterproof", "comfortable"]
                          }
                        }
                        """,
                topic, vocabList, difficulty);
    }
}
