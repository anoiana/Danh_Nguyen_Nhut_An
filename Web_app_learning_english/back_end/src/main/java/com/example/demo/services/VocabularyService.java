package com.example.demo.services;

import com.example.demo.entities.Definition;
import com.example.demo.entities.Folder;
import com.example.demo.entities.Meaning;
import com.example.demo.entities.Vocabulary;
import com.example.demo.entities.dto.VocabularyDTO.*;
import com.example.demo.repositories.DefinitionRepository;
import com.example.demo.repositories.FolderRepository;
import com.example.demo.repositories.MeaningRepository;
import com.example.demo.repositories.VocabularyRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class VocabularyService {

    @Autowired
    private VocabularyRepository vocabularyRepository;

    @Autowired
    private FolderRepository folderRepository;

    @Autowired
    private MeaningRepository meaningRepository;

    @Autowired
    private DefinitionRepository definitionRepository;

    /**
     * Creates a new vocabulary entry in a folder.
     * Checks if the folder has reached its limit of 100 vocabularies.
     *
     * @param dto The data transfer object containing vocabulary details.
     * @return The created Vocabulary entity.
     * @throws RuntimeException if the folder limit is reached or folder is not
     *                          found.
     */
    @Transactional
    public Vocabulary createVocabulary(DictionaryEntryDTO dto) {
        if (vocabularyRepository.countByFolderId(dto.folderId()) >= 100) {
            throw new RuntimeException("Lỗi: Mỗi thư mục chỉ được chứa tối đa 100 từ vựng.");
        }

        Folder folder = folderRepository.findById(dto.folderId())
                .orElseThrow(() -> new RuntimeException("Folder not found with id: " + dto.folderId()));

        Vocabulary vocab = new Vocabulary();
        vocab.setWord(dto.word());
        vocab.setPhoneticText(dto.phoneticText());
        vocab.setAudioUrl(dto.audioUrl());
        vocab.setFolder(folder);
        vocab.setUserDefinedMeaning(dto.userDefinedMeaning());
        vocab.setUserImageBase64(dto.userImageBase64());
        vocab.setMeanings(new ArrayList<>());

        Vocabulary savedVocab = vocabularyRepository.save(vocab);

        if (dto.meanings() != null) {
            for (MeaningDTO meaningDto : dto.meanings()) {
                Meaning meaning = new Meaning();
                meaning.setPartOfSpeech(meaningDto.partOfSpeech());
                meaning.setSynonyms(meaningDto.synonyms());
                meaning.setAntonyms(meaningDto.antonyms());
                meaning.setVocabulary(savedVocab);
                meaning.setDefinitions(new ArrayList<>());
                Meaning savedMeaning = meaningRepository.save(meaning);

                if (meaningDto.definitions() != null) {
                    for (DefinitionDTO defDto : meaningDto.definitions()) {
                        Definition definition = new Definition();
                        definition.setDefinition(defDto.definition());
                        definition.setExample(defDto.example());
                        definition.setMeaning(savedMeaning);
                        definitionRepository.save(definition);
                    }
                }
            }
        }
        return vocabularyRepository.findById(savedVocab.getId()).orElse(savedVocab);
    }

    /**
     * Retrieves usages of a specific word in a folder with pagination and search.
     *
     * @param folderId The ID of the folder to search in.
     * @param page     The page number (0-indexed).
     * @param size     The number of items per page.
     * @param search   The search string to filter words.
     * @return A Page of Vocabulary entities.
     */
    public Page<Vocabulary> getVocabulariesByFolder(Long folderId, int page, int size, String search) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("word").ascending());
        return vocabularyRepository.findByFolderIdAndWordContainingIgnoreCase(folderId, search, pageable);
    }

    /**
     * Updates the custom image for a vocabulary.
     *
     * @param vocabularyId The ID of the vocabulary to update.
     * @param imageUrl     The new image URL (or Base64 string).
     * @return The updated Vocabulary entity, or null if not found.
     */
    public Vocabulary updateVocabularyImage(Long vocabularyId, String imageUrl) {
        Optional<Vocabulary> vocabOpt = vocabularyRepository.findById(vocabularyId);
        if (vocabOpt.isPresent()) {
            Vocabulary vocab = vocabOpt.get();
            String cleanImageUrl = imageUrl.replaceAll("^\"|\"$", "");
            vocab.setUserImageBase64(cleanImageUrl);
            return vocabularyRepository.save(vocab);
        }
        return null;
    }

    /**
     * Updates user-defined fields (meaning, image) of a vocabulary.
     *
     * @param vocabularyId The ID of the vocabulary to update.
     * @param updateDTO    The DTO containing the new values.
     * @return The updated Vocabulary entity, or null if not found.
     */
    public Vocabulary updateVocabulary(Long vocabularyId, VocabularyUserUpdateDTO updateDTO) {
        Optional<Vocabulary> vocabOpt = vocabularyRepository.findById(vocabularyId);
        if (vocabOpt.isPresent()) {
            Vocabulary vocab = vocabOpt.get();
            vocab.setUserDefinedMeaning(updateDTO.userDefinedMeaning());
            vocab.setUserImageBase64(updateDTO.userImageBase64());
            return vocabularyRepository.save(vocab);
        }
        return null;
    }

    /**
     * Deletes a vocabulary by its ID.
     *
     * @param vocabularyId The ID of the vocabulary to delete.
     * @return true if deleted successfully, false if not found.
     */
    public boolean deleteVocabulary(Long vocabularyId) {
        if (!vocabularyRepository.existsById(vocabularyId)) {
            return false;
        }
        vocabularyRepository.deleteById(vocabularyId);
        return true;
    }

    /**
     * Deletes multiple vocabularies in batch.
     * Handles deletion of related meanings and definitions to maintain integrity.
     *
     * @param vocabularyIds The list of vocabulary IDs to delete.
     * @return The number of deleted vocabularies.
     * @throws RuntimeException if the list of IDs is empty.
     */
    @Transactional
    public int deleteBatchVocabularies(List<Long> vocabularyIds) {
        if (vocabularyIds == null || vocabularyIds.isEmpty()) {
            throw new RuntimeException("Vocabulary IDs list cannot be empty.");
        }
        List<Long> meaningIds = meaningRepository.findMeaningIdsByVocabularyIds(vocabularyIds);
        if (!meaningIds.isEmpty()) {
            definitionRepository.deleteByMeaningIds(meaningIds);
            meaningRepository.deleteAllByIdInBatch(meaningIds);
        }
        vocabularyRepository.deleteAllByIdInBatch(vocabularyIds);
        return vocabularyIds.size();
    }

    /**
     * Moves multiple vocabularies to a target folder.
     *
     * @param vocabularyIds  The list of vocabulary IDs to move.
     * @param targetFolderId The ID of the destination folder.
     * @return The number of moved vocabularies.
     * @throws RuntimeException if the list is empty or target folder is not found.
     */
    @Transactional
    public int moveBatchVocabularies(List<Long> vocabularyIds, Long targetFolderId) {
        if (vocabularyIds == null || vocabularyIds.isEmpty()) {
            throw new RuntimeException("Vocabulary IDs list cannot be empty.");
        }
        Folder targetFolder = folderRepository.findById(targetFolderId)
                .orElseThrow(() -> new RuntimeException("Target folder not found with id: " + targetFolderId));
        List<Vocabulary> vocabulariesToMove = vocabularyRepository.findAllById(vocabularyIds);
        for (Vocabulary vocab : vocabulariesToMove) {
            vocab.setFolder(targetFolder);
        }
        vocabularyRepository.saveAll(vocabulariesToMove);
        return vocabulariesToMove.size();
    }
}
