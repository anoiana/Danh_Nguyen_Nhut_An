package com.example.demo.entities;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Entity
@Getter
@Setter
@NoArgsConstructor
public class Meaning {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String partOfSpeech;

    @OneToMany(mappedBy = "meaning", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Definition> definitions;

    @ElementCollection(fetch = FetchType.LAZY)
    private List<String> synonyms;

    @ElementCollection(fetch = FetchType.LAZY)
    private List<String> antonyms;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vocabulary_id", nullable = false)
    @JsonBackReference
    private Vocabulary vocabulary;
}