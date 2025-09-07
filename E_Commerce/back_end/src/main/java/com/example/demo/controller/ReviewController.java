package com.example.demo.controller;

import com.example.demo.dto.CreateOrderRequestDTO;
import com.example.demo.dto.CustomerDetailViewDTO;
import com.example.demo.model.Product;
import com.example.demo.model.Review;
import com.example.demo.model.User;
import com.example.demo.repository.ProductRepository;
import com.example.demo.repository.ReviewRepository;
import com.example.demo.repository.UserRepository;
import com.example.demo.security.services.UserDetailsImpl;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api")
public class ReviewController {

    @Autowired private ReviewRepository reviewRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private ProductRepository productRepository;

    @GetMapping("/products/{productId}/reviews")
    @Transactional(readOnly = true)
    public ResponseEntity<List<CreateOrderRequestDTO.ReviewDTO>> getReviewsForProduct(@PathVariable Long productId) {
        List<Review> reviews = reviewRepository.findByProductIdOrderByReviewDateDesc(productId);
        List<CreateOrderRequestDTO.ReviewDTO> dtos = reviews.stream().map(this::convertToDTO).collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    @GetMapping("/products/{productId}/reviews/check")
    public ResponseEntity<?> checkUserReviewAbility(@PathVariable Long productId) {
        UserDetailsImpl userDetails = getCurrentUserDetails();
        if (userDetails == null) {
            return ResponseEntity.ok(Map.of("canReview", false, "reason", "NOT_LOGGED_IN"));
        }
        boolean hasReviewed = reviewRepository.existsByUserIdAndProductId(userDetails.getId(), productId);
        return ResponseEntity.ok(Map.of("canReview", !hasReviewed, "reason", hasReviewed ? "ALREADY_REVIEWED" : "CAN_REVIEW"));
    }

    @PostMapping("/products/{productId}/reviews")
    @Transactional
    public ResponseEntity<?> addReview(@PathVariable Long productId, @RequestBody CreateOrderRequestDTO.ReviewRequestDTO reviewRequest) {
        UserDetailsImpl userDetails = getCurrentUserDetails();
        User user = userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new EntityNotFoundException("User not found"));
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new EntityNotFoundException("Product not found"));

        if (reviewRepository.existsByUserIdAndProductId(user.getId(), productId)) {
            return ResponseEntity.badRequest().body("Bạn đã đánh giá sản phẩm này rồi.");
        }

        Review review = new Review();
        review.setUser(user);
        review.setProduct(product);
        review.setRating(reviewRequest.getRating());
        review.setComment(reviewRequest.getComment());
        review.setReviewDate(LocalDateTime.now());

        Review savedReview = reviewRepository.save(review);
        return ResponseEntity.ok(convertToDTO(savedReview));
    }

    @PutMapping("/reviews/{reviewId}")
    @Transactional
    public ResponseEntity<?> updateReview(@PathVariable Long reviewId, @RequestBody CreateOrderRequestDTO.ReviewRequestDTO reviewRequest) {
        UserDetailsImpl userDetails = getCurrentUserDetails();
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new EntityNotFoundException("Review not found"));

        if (!review.getUser().getId().equals(userDetails.getId())) {
            return ResponseEntity.status(403).body("Bạn không có quyền sửa đánh giá này.");
        }

        review.setRating(reviewRequest.getRating());
        review.setComment(reviewRequest.getComment());
        review.setReviewDate(LocalDateTime.now());

        Review updatedReview = reviewRepository.save(review);
        return ResponseEntity.ok(convertToDTO(updatedReview));
    }

    @DeleteMapping("/reviews/{reviewId}")
    @Transactional
    public ResponseEntity<?> deleteReview(@PathVariable Long reviewId) {
        UserDetailsImpl userDetails = getCurrentUserDetails();
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new EntityNotFoundException("Review not found"));

        if (!review.getUser().getId().equals(userDetails.getId())) {
            return ResponseEntity.status(403).body("Bạn không có quyền xóa đánh giá này.");
        }

        reviewRepository.delete(review);
        return ResponseEntity.ok().build();
    }

    private UserDetailsImpl getCurrentUserDetails() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || authentication.getPrincipal().equals("anonymousUser")) {
            return null;
        }
        return (UserDetailsImpl) authentication.getPrincipal();
    }

    private CreateOrderRequestDTO.ReviewDTO convertToDTO(Review review) {
        CreateOrderRequestDTO.ReviewDTO dto = new CreateOrderRequestDTO.ReviewDTO();
        dto.setId(review.getId());
        dto.setRating(review.getRating());
        dto.setComment(review.getComment());
        dto.setReviewDate(review.getReviewDate());
        dto.setUsername(review.getUser().getUsername());
        dto.setUserId(review.getUser().getId());
        dto.setAvatarUrl(review.getUser().getAvatarUrl());
        return dto;
    }

    @GetMapping("/products/{productId}/reviews/stats")
    @Transactional(readOnly = true)
    public ResponseEntity<CustomerDetailViewDTO.ReviewStatsDTO> getReviewStats(@PathVariable Long productId) {
        List<Review> reviews = reviewRepository.findByProductIdOrderByReviewDateDesc(productId);

        if (reviews.isEmpty()) {
            return ResponseEntity.ok(new CustomerDetailViewDTO.ReviewStatsDTO()); // Trả về DTO rỗng
        }

        double averageRating = reviews.stream()
                .mapToInt(Review::getRating)
                .average()
                .orElse(0.0);

        Map<Integer, Long> ratingCounts = reviews.stream()
                .collect(Collectors.groupingBy(Review::getRating, Collectors.counting()));

        // Đảm bảo có đủ 5 mức sao
        for (int i = 1; i <= 5; i++) {
            ratingCounts.putIfAbsent(i, 0L);
        }

        CustomerDetailViewDTO.ReviewStatsDTO stats = new CustomerDetailViewDTO.ReviewStatsDTO();
        stats.setAverageRating(Math.round(averageRating * 10.0) / 10.0); // Làm tròn đến 1 chữ số thập phân
        stats.setTotalReviews(reviews.size());
        stats.setRatingCounts(ratingCounts);

        return ResponseEntity.ok(stats);
    }
}