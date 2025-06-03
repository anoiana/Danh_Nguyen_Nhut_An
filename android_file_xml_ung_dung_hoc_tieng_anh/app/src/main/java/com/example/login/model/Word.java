package com.example.login.model;

import android.net.Uri;

import java.io.Serializable;

public class Word implements Serializable {
    private String wordId;
    private String englishWord;
    private String vietnameseMeaning;
    private String description;
    private String imageUri;
    private boolean starred;
    private int correctCount;

    public int getCorrectCount() {
        return correctCount;
    }

    public void setCorrectCount(int correctCount) {
        this.correctCount = correctCount;
    }

    public Word() {
    }


    public Word(String wordId, String englishWord, String vietnameseMeaning, String description, String imageUri, boolean starred, int correctCount) {
        this.wordId = wordId;
        this.englishWord = englishWord;
        this.vietnameseMeaning = vietnameseMeaning;
        this.description = description;
        this.imageUri = imageUri;
        this.starred = starred;
        this.correctCount = correctCount;
    }

    public boolean isStarred() {
        return starred;
    }

    public void setStarred(boolean starred) {
        this.starred = starred;
    }

    public Word(String wordId, String englishWord, String vietnameseMeaning, String description) {
        this.wordId = wordId;
        this.englishWord = englishWord;
        this.vietnameseMeaning = vietnameseMeaning;
        this.description = description;
        this.imageUri = null; // Default to null for CSV import
    }

    public Word(String wordId, String englishWord, String vietnameseMeaning, String description, String imageUri) {
        this.wordId = wordId;
        this.englishWord = englishWord;
        this.vietnameseMeaning = vietnameseMeaning;
        this.description = description;
        this.imageUri = imageUri;
    }



    public String getEnglishWord() {
        return englishWord;
    }

    public void setEnglishWord(String englishWord) {
        this.englishWord = englishWord;
    }

    public String getWordId() {
        return wordId;
    }

    public void setWordId(String wordId) {
        this.wordId = wordId;
    }

    public String getVietnameseMeaning() {
        return vietnameseMeaning;
    }

    public void setVietnameseMeaning(String vietnameseMeaning) {
        this.vietnameseMeaning = vietnameseMeaning;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getImageUri() {
        return imageUri;
    }

    public void setImageUri(String imageUri) {
        this.imageUri = imageUri;
    }

    @Override
    public String toString() {
        return "Word{" +
                "englishWord='" + englishWord + '\'' +
                ", starred=" + starred +
                ", wordId='" + wordId + '\'' +
                '}';
    }
}
