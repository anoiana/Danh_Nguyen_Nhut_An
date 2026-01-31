package com.example.demo.services;

// src/main/java/com/example/demo/services/TranslationService.java

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import okhttp3.*;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@Service
public class TranslationService {

    // MyMemory Translation API - Miễn phí, không cần API key
    private static final String MYMEMORY_API_URL = "https://api.mymemory.translated.net/get";

    private final OkHttpClient client = new OkHttpClient();

    /**
     * Dịch từ tiếng Anh sang tiếng Việt sử dụng MyMemory Translation API
     * 
     * @param word từ hoặc câu cần dịch
     * @return bản dịch tiếng Việt
     */
    public String translateWord(String word) throws IOException {
        // Encode từ cần dịch để đưa vào URL
        String encodedWord = URLEncoder.encode(word, StandardCharsets.UTF_8);

        // Tạo URL với tham số: q=text, langpair=source|target
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

            // Kiểm tra response status
            int responseStatus = rootNode.path("responseStatus").asInt();
            if (responseStatus != 200) {
                String errorMessage = rootNode.path("responseDetails").asText();
                System.err.println("Translation API returned error: " + errorMessage);
                return "Lỗi dịch: " + errorMessage;
            }

            // Lấy bản dịch từ responseData.translatedText
            JsonNode translatedTextNode = rootNode.path("responseData").path("translatedText");

            if (translatedTextNode.isMissingNode() || translatedTextNode.isNull()) {
                return "Không có bản dịch.";
            }

            return translatedTextNode.asText();
        }
    }

    /**
     * Dịch với ngôn ngữ nguồn và đích tùy chỉnh
     * 
     * @param text       văn bản cần dịch
     * @param sourceLang mã ngôn ngữ nguồn (ví dụ: "en", "vi", "fr")
     * @param targetLang mã ngôn ngữ đích
     * @return bản dịch
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