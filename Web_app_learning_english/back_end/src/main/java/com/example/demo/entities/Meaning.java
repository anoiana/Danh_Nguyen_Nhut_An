package com.example.demo.entities;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.ArrayList;
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
    @CollectionTable(name = "meaning_synonym_list", joinColumns = @JoinColumn(name = "meaning_id"))
    @Column(name = "synonym_word")
    private List<String> synonyms = new ArrayList<>();

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(name = "meaning_antonym_list", joinColumns = @JoinColumn(name = "meaning_id"))
    @Column(name = "antonym_word")
    private List<String> antonyms = new ArrayList<>();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vocabulary_id", nullable = false)
    @JsonBackReference
    private Vocabulary vocabulary;
}