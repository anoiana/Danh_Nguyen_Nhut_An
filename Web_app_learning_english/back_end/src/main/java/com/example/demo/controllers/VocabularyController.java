package com.example.demo.controllers;

import com.example.demo.entities.Vocabulary;
import com.example.demo.entities.dto.VocabularyDTO.*;
import com.example.demo.services.VocabularyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/vocabularies")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class VocabularyController {

    @Autowired
    private VocabularyService vocabularyService;

    @PostMapping
    public ResponseEntity<?> createVocabulary(@RequestBody DictionaryEntryDTO dto) {
        try {
            Vocabulary savedVocab = vocabularyService.createVocabulary(dto);
            return ResponseEntity.ok(savedVocab);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/folder/{folderId}")
    public Page<Vocabulary> getVocabulariesByFolder(
            @PathVariable Long folderId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "15") int size,
            @RequestParam(defaultValue = "") String search) {
        return vocabularyService.getVocabulariesByFolder(folderId, page, size, search);
    }

    @PutMapping("/{vocabularyId}/image")
    public ResponseEntity<Vocabulary> updateVocabularyImage(
            @PathVariable Long vocabularyId,
            @RequestBody String imageUrl) {
        Vocabulary updatedVocab = vocabularyService.updateVocabularyImage(vocabularyId, imageUrl);
        if (updatedVocab == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(updatedVocab);
    }

    @PutMapping("/{vocabularyId}")
    public ResponseEntity<Vocabulary> updateVocabulary(
            @PathVariable Long vocabularyId,
            @RequestBody VocabularyUserUpdateDTO updateDTO) {
        Vocabulary updatedVocab = vocabularyService.updateVocabulary(vocabularyId, updateDTO);
        if (updatedVocab == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(updatedVocab);
    }

    @DeleteMapping("/{vocabularyId}")
    public ResponseEntity<String> deleteVocabulary(@PathVariable Long vocabularyId) {
        boolean deleted = vocabularyService.deleteVocabulary(vocabularyId);
        if (!deleted) {
            return ResponseEntity.status(404).body("Vocabulary not found with id: " + vocabularyId);
        }
        return ResponseEntity.ok("Vocabulary with id " + vocabularyId + " has been deleted successfully.");
    }

    @PostMapping("/batch-delete")
    public ResponseEntity<String> deleteBatchVocabularies(@RequestBody BatchDeleteRequestDTO request) {
        try {
            int count = vocabularyService.deleteBatchVocabularies(request.vocabularyIds());
            return ResponseEntity.ok("Successfully deleted " + count + " vocabularies.");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PutMapping("/batch-move")
    public ResponseEntity<String> moveBatchVocabularies(@RequestBody BatchMoveRequestDTO request) {
        try {
            int count = vocabularyService.moveBatchVocabularies(request.vocabularyIds(), request.targetFolderId());
            return ResponseEntity.ok("Successfully moved " + count + " vocabularies.");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}