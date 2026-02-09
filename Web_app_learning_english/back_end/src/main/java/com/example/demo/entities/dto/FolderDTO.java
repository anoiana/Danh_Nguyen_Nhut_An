package com.example.demo.entities.dto;


public class FolderDTO {
    public record FolderCreationDTO(String name, Long userId) {}
    public record FolderUpdateDTO(String newName) {}
}