package com.example.demo.features.user.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class UserDto {
    private Long id;

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "Name is required")
    @Size(min = 2, max = 50, message = "Name must be between 2 and 50 characters")
    private String name;

    private String password;

    @Min(value = 18, message = "You must be at least 18 years old")
    @Max(value = 100, message = "Invalid age")
    private Integer age;

    private String gender;

    @Size(max = 200, message = "Bio cannot exceed 200 characters")
    private String bio;

    private String avatarUrl;
    private String interests;
    private String photos;
}
