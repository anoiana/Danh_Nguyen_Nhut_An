// Trong package com.example.demo.service
package com.example.demo.service;

import com.example.demo.dto.ProductCardDTO;
import com.example.demo.model.Product;
import com.example.demo.model.Promotion;
import com.example.demo.model.Review; // <-- Cần import Review
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ProductService {

    public ProductCardDTO convertToProductCardDTO(Product product) {
        ProductCardDTO dto = new ProductCardDTO();
        dto.setId(product.getId());
        dto.setName(product.getName());

        // === SỬA LỖI ẢNH ===
        // Sử dụng getPrimaryImageUrl() để lấy ảnh đầu tiên làm ảnh đại diện.
        dto.setImageUrl(product.getPrimaryImageUrl());

        // === TÍNH TOÁN GIÁ ===
        double originalPrice = product.getSalePrice();
        dto.setOriginalPrice(originalPrice);
        dto.setSalePrice(originalPrice); // Giá mặc định

        // Tìm khuyến mãi hợp lệ
        LocalDate today = LocalDate.now();
        Promotion activePromotion = product.getPromotions().stream()
                .filter(p -> p.isActive() && !today.isBefore(p.getStartDate()) && !today.isAfter(p.getEndDate()))
                .findFirst()
                .orElse(null);

        if (activePromotion != null) {
            int discountPercent = activePromotion.getDiscountPercentage();
            double discountedPrice = originalPrice * (1 - discountPercent / 100.0);
            dto.setSalePrice(discountedPrice);
            dto.setDiscountPercentage(discountPercent);
        }

        // === BỔ SUNG: TÍNH TOÁN RATING VÀ REVIEW COUNT ===
        List<Review> reviews = product.getReviews();
        if (reviews != null && !reviews.isEmpty()) {
            dto.setReviewCount(reviews.size());
            double average = reviews.stream()
                    .mapToInt(Review::getRating)
                    .average()
                    .orElse(0.0);
            // Làm tròn đến 1 chữ số thập phân
            dto.setAverageRating(Math.round(average * 10.0) / 10.0);
        } else {
            dto.setReviewCount(0);
            dto.setAverageRating(0.0);
        }

        return dto;
    }

    public List<ProductCardDTO> convertToProductCardDTOList(List<Product> products) {
        return products.stream()
                .map(this::convertToProductCardDTO)
                .collect(Collectors.toList());
    }
}