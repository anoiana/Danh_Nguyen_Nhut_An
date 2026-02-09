package com.example.demo.services;

import com.example.demo.entities.Folder;
import com.example.demo.entities.User;
import com.example.demo.entities.dto.FolderDTO.*;
import com.example.demo.entities.dto.FolderResponseDTO;
import com.example.demo.repositories.FolderRepository;
import com.example.demo.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

@Service
public class FolderService {

    @Autowired
    private FolderRepository folderRepository;

    @Autowired
    private UserRepository userRepository;

    /**
     * Creates a new folder for a user.
     * Enforces a limit of 100 folders per user.
     *
     * @param folderDTO DTO containing folder name and user ID.
     * @return FolderResponseDTO of the created folder.
     * @throws RuntimeException if user limit is reached or user not found.
     */
    public FolderResponseDTO createFolder(FolderCreationDTO folderDTO) {
        if (folderRepository.countByUserId(folderDTO.userId()) >= 100) {
            throw new RuntimeException("Lỗi: Mỗi người dùng chỉ được tạo tối đa 100 thư mục.");
        }
        User user = userRepository.findById(folderDTO.userId())
                .orElseThrow(() -> new RuntimeException("Error: User not found with id " + folderDTO.userId()));

        Folder newFolder = new Folder();
        newFolder.setName(folderDTO.name());
        newFolder.setUser(user);
        Folder savedFolder = folderRepository.save(newFolder);

        return new FolderResponseDTO(
                savedFolder.getId(),
                savedFolder.getName(),
                savedFolder.getUser().getId(),
                0L);
    }

    /**
     * Retrieves folders for a specific user with pagination and search.
     *
     * @param userId The ID of the user.
     * @param page   Page number (0-based).
     * @param size   Page size.
     * @param search Search keyword for folder name.
     * @return A Page of FolderResponseDTO.
     */
    public Page<FolderResponseDTO> getFoldersByUser(Long userId, int page, int size, String search) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("name").ascending());
        return folderRepository.findWithSearchAndPagination(userId, search, pageable);
    }

    /**
     * Updates an existing folder's name.
     *
     * @param folderId  The ID of the folder to update.
     * @param updateDTO DTO containing the new name.
     * @return FolderResponseDTO of the updated folder, or null if not found.
     */
    public FolderResponseDTO updateFolder(Long folderId, FolderUpdateDTO updateDTO) {
        return folderRepository.findById(folderId)
                .map(existingFolder -> {
                    existingFolder.setName(updateDTO.newName());
                    Folder updatedFolder = folderRepository.save(existingFolder);

                    long vocabCount = existingFolder.getVocabularies() != null ? existingFolder.getVocabularies().size()
                            : 0;

                    return new FolderResponseDTO(
                            updatedFolder.getId(),
                            updatedFolder.getName(),
                            updatedFolder.getUser().getId(),
                            vocabCount);
                }).orElse(null);
    }

    /**
     * Deletes a folder by ID.
     *
     * @param folderId The ID of the folder to delete.
     * @return true if deleted, false if not found.
     */
    public boolean deleteFolder(Long folderId) {
        if (!folderRepository.existsById(folderId)) {
            return false;
        }
        folderRepository.deleteById(folderId);
        return true;
    }
}
