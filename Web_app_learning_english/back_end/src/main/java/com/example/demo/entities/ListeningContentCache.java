package com.example.demo.entities;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter
@Setter
@NoArgsConstructor
@Table(name = "listening_content_cache", indexes = {
        @Index(name = "idx_listening_cache", columnList = "folderId, level, topic, gameSubType")
})
public class ListeningContentCache {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long folderId;
    private int level;
    private String topic;

    /**
     * Game sub-type: 'mcq' or 'fitb'
     */
    @Column(length = 10)
    private String gameSubType;

    @Column(columnDefinition = "TEXT")
    private String plainTranscript;

    @Column(columnDefinition = "TEXT")
    private String mcqJson;

    @Column(columnDefinition = "TEXT")
    private String fitbJson;
}