package com.example.demo.controllers;

import com.example.demo.entities.dto.FolderResponseDTO;
import com.example.demo.entities.dto.FolderDTO.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/folders")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class FolderController {

    @Autowired
    private com.example.demo.services.FolderService folderService;

    @PostMapping
    public ResponseEntity<?> createFolder(@RequestBody FolderCreationDTO folderDTO) {
        try {
            FolderResponseDTO response = folderService.createFolder(folderDTO);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            if (e.getMessage().startsWith("Lỗi: Mỗi người dùng")) {
                return ResponseEntity.badRequest().body(e.getMessage());
            }
            throw e;
        }
    }

    @GetMapping("/user/{userId}")
    public Page<FolderResponseDTO> getFoldersByUser(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "15") int size,
            @RequestParam(defaultValue = "") String search) {
        return folderService.getFoldersByUser(userId, page, size, search);
    }

    @PutMapping("/{folderId}")
    public ResponseEntity<FolderResponseDTO> updateFolder(
            @PathVariable Long folderId,
            @RequestBody FolderUpdateDTO updateDTO) {
        FolderResponseDTO response = folderService.updateFolder(folderId, updateDTO);
        if (response == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{folderId}")
    public ResponseEntity<String> deleteFolder(@PathVariable Long folderId) {
        boolean deleted = folderService.deleteFolder(folderId);
        if (!deleted) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok("Folder with id " + folderId + " has been deleted successfully.");
    }
}