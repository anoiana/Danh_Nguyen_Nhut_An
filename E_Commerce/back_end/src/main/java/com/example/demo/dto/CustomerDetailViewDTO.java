package com.example.demo.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

import java.util.List;
import java.util.Map;

public class CustomerDetailViewDTO {
    private Long id;
    private String username;
    private String email;
    private String phoneNumber;
    private String address;
    private String province;
    private String district;
    private String ward;
    private String notes;
    private boolean enabled;

    // Danh sách các đơn hàng đã được tóm tắt
    private List<OrderSummaryDTO> orderHistory;
    // Tổng số tiền đã chi tiêu
    private Double totalSpent;


    public static class ForgotPasswordRequest {
        @NotBlank
        @Email
        private String email;

        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
    }

    public static class LoginRequest {
        @NotBlank
        @Email
        private String email;

        @NotBlank
        private String password;

        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
    }

    public static class JwtResponse {
        private String token;
        private String type = "Bearer";
        private Long id;
        private String username;
        private String email;
        private List<String> roles;

        public JwtResponse(String accessToken, Long id, String username, String email, List<String> roles) {
            this.token = accessToken;
            this.id = id;
            this.username = username;
            this.email = email;
            this.roles = roles;
        }

        public String getToken() { return token; }
        public String getType() { return type; }
        public Long getId() { return id; }
        public String getUsername() { return username; }
        public String getEmail() { return email; }
        public List<String> getRoles() { return roles; }
    }

    public static class MessageResponse {
        private String message;

        public MessageResponse(String message) {
            this.message = message;
        }

        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }
    }

    public static class ReviewStatsDTO {
        private double averageRating;
        private long totalReviews;
        private Map<Integer, Long> ratingCounts; // Key: 1-5, Value: số lượng

        // Getters and Setters...
        public double getAverageRating() { return averageRating; }
        public void setAverageRating(double averageRating) { this.averageRating = averageRating; }
        public long getTotalReviews() { return totalReviews; }
        public void setTotalReviews(long totalReviews) { this.totalReviews = totalReviews; }
        public Map<Integer, Long> getRatingCounts() { return ratingCounts; }
        public void setRatingCounts(Map<Integer, Long> ratingCounts) { this.ratingCounts = ratingCounts; }
    }
}