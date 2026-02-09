package com.example.demo.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@Service
public class GrammarService {

    @Autowired
    private AiGrammarService aiGrammarService;

    /**
     * Analyzes a user's answer using AI to check for completeness and grammar
     * correctness.
     *
     * @param text The user's input text.
     * @return A GrammarAnalysisResult containing completeness status and a list of
     *         errors.
     */
    public AiGrammarService.GrammarAnalysisResult analyze(String text) {
        try {
            return aiGrammarService.analyzeSentence(text);
        } catch (IOException e) {
            e.printStackTrace();
            List<String> errors = new ArrayList<>();
            errors.add("Không thể kiểm tra ngữ pháp lúc này do lỗi hệ thống.");
            return new AiGrammarService.GrammarAnalysisResult(true, errors, null);
        }
    }
}