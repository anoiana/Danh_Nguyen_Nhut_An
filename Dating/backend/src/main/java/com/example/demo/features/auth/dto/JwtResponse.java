package com.example.demo.features.auth.dto;

import lombok.Data;
import java.util.List;

@Data
public class JwtResponse {
    private String token;
    private String type = "Bearer";
    private Long id;
    private String email;
    private String name;
    private Integer age;
    private String gender;
    private String bio;
    private String avatarUrl;
    private String interests;
    private String photos;
    private List<String> roles;

    public JwtResponse(String accessToken, Long id, String email, String name, Integer age, String gender, String bio,
            String avatarUrl, String interests, String photos, List<String> roles) {
        this.token = accessToken;
        this.id = id;
        this.email = email;
        this.name = name;
        this.age = age;
        this.gender = gender;
        this.bio = bio;
        this.avatarUrl = avatarUrl;
        this.interests = interests;
        this.photos = photos;
        this.roles = roles;
    }
}
