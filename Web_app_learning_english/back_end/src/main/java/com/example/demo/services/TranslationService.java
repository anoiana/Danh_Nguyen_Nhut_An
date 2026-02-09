package com.example.demo.services;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import okhttp3.*;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@Service
public class TranslationService {

    // MyMemory Translation API - Free, no API key required
    private static final String MYMEMORY_API_URL = "https://api.mymemory.translated.net/get";

    private final OkHttpClient client = new OkHttpClient();

    /**
     * Translates a word or sentence from English to Vietnamese using MyMemory
     * Translation API.
     *
     * @param word The word or sentence to translate.
     * @return The Vietnamese translation.
     * @throws IOException if the API request fails.
     */
    public String translateWord(String word) throws IOException {
        // Encode the word to be URL safe
        String encodedWord = URLEncoder.encode(word, StandardCharsets.UTF_8);

        // Create URL with parameters: q=text, langpair=source|target
        String url = MYMEMORY_API_URL + "?q=" + encodedWord + "&langpair=en|vi";

        Request request = new Request.Builder()
                .url(url)
                .get()
                .addHeader("Accept", "application/json")
                .build();

        try (Response response = client.newCall(request).execute()) {
            String responseBody = response.body().string();

            if (!response.isSuccessful()) {
                System.err.println("Translation API Error Body: " + responseBody);
                throw new IOException("Unexpected code from Translation API: " + response.code());
            }

            System.out.println("MyMemory Translation API Response: " + responseBody);

            ObjectMapper objectMapper = new ObjectMapper();
            JsonNode rootNode = objectMapper.readTree(responseBody);

            // Check response status
            int responseStatus = rootNode.path("responseStatus").asInt();
            if (responseStatus != 200) {
                String errorMessage = rootNode.path("responseDetails").asText();
                System.err.println("Translation API returned error: " + errorMessage);
                return "Lỗi dịch: " + errorMessage;
            }

            // Get translation from responseData.translatedText
            JsonNode translatedTextNode = rootNode.path("responseData").path("translatedText");

            if (translatedTextNode.isMissingNode() || translatedTextNode.isNull()) {
                return "Không có bản dịch.";
            }

            return translatedTextNode.asText();
        }
    }

    /**
     * Translates text with specified source and target languages.
     *
     * @param text       The text to translate.
     * @param sourceLang The source language code (e.g., "en", "vi").
     * @param targetLang The target language code.
     * @return The translation result.
     * @throws IOException if the API request fails.
     */
    public String translate(String text, String sourceLang, String targetLang) throws IOException {
        String encodedText = URLEncoder.encode(text, StandardCharsets.UTF_8);
        String url = MYMEMORY_API_URL + "?q=" + encodedText + "&langpair=" + sourceLang + "|" + targetLang;

        Request request = new Request.Builder()
                .url(url)
                .get()
                .addHeader("Accept", "application/json")
                .build();

        try (Response response = client.newCall(request).execute()) {
            String responseBody = response.body().string();

            if (!response.isSuccessful()) {
                throw new IOException("Unexpected code from Translation API: " + response.code());
            }

            ObjectMapper objectMapper = new ObjectMapper();
            JsonNode rootNode = objectMapper.readTree(responseBody);

            int responseStatus = rootNode.path("responseStatus").asInt();
            if (responseStatus != 200) {
                return "Lỗi dịch: " + rootNode.path("responseDetails").asText();
            }

            JsonNode translatedTextNode = rootNode.path("responseData").path("translatedText");
            if (translatedTextNode.isMissingNode() || translatedTextNode.isNull()) {
                return "Không có bản dịch.";
            }

            return translatedTextNode.asText();
        }
    }
}