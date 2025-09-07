// src/main/java/com/example/demo/entities/ListeningContentCache.java
package com.example.demo.entities;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Getter
@Setter
@Table(name = "listening_content_cache", indexes = {
        // Cập nhật index để bao gồm cả gameSubType
        @Index(name = "idx_listening_cache", columnList = "folderId, level, topic, gameSubType")
})
public class ListeningContentCache {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long folderId;
    private int level;
    private String topic;

    @Column(length = 10) // 'mcq' hoặc 'fitb'
    private String gameSubType; // <<< THÊM TRƯỜNG MỚI

    @Column(columnDefinition = "TEXT")
    private String plainTranscript;

    @Column(columnDefinition = "TEXT")
    private String mcqJson;

    @Column(columnDefinition = "TEXT")
    private String fitbJson;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getFolderId() {
        return folderId;
    }

    public void setFolderId(Long folderId) {
        this.folderId = folderId;
    }

    public int getLevel() {
        return level;
    }

    public void setLevel(int level) {
        this.level = level;
    }

    public String getTopic() {
        return topic;
    }

    public void setTopic(String topic) {
        this.topic = topic;
    }

    public String getGameSubType() {
        return gameSubType;
    }

    public void setGameSubType(String gameSubType) {
        this.gameSubType = gameSubType;
    }

    public String getPlainTranscript() {
        return plainTranscript;
    }

    public void setPlainTranscript(String plainTranscript) {
        this.plainTranscript = plainTranscript;
    }

    public String getMcqJson() {
        return mcqJson;
    }

    public void setMcqJson(String mcqJson) {
        this.mcqJson = mcqJson;
    }

    public String getFitbJson() {
        return fitbJson;
    }

    public void setFitbJson(String fitbJson) {
        this.fitbJson = fitbJson;
    }
}