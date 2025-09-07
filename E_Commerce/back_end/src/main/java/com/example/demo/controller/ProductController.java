package com.example.demo.controller;

import com.example.demo.model.Product;
import com.example.demo.model.Promotion;
import com.example.demo.repository.ProductRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/products")
public class ProductController {

    @Autowired
    private ProductRepository productRepository;

    @GetMapping("/{id}")
    @Transactional(readOnly = true)
    public ResponseEntity<Map<String, Object>> getProductDetails(@PathVariable Long id) {
        // Vì imageUrls được fetch EAGER, nên findById là đủ
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Product not found"));

        Map<String, Object> response = new HashMap<>();
        response.put("id", product.getId());
        response.put("name", product.getName());
        response.put("description", product.getDescription());

        // ▼▼▼ THAY ĐỔI LỚN TẠI ĐÂY ▼▼▼
        // Thay vì gửi một ảnh, chúng ta gửi cả danh sách ảnh.
        // Frontend sẽ dùng danh sách này để hiển thị gallery ảnh cho khách hàng.
        response.put("imageUrls", product.getImageUrls());
        // ▲▲▲ KẾT THÚC THAY ĐỔI ▲▲▲

        response.put("category", product.getCategory());
        response.put("variants", product.getVariants());
        response.put("originalPrice", product.getSalePrice());

        // Logic tính toán khuyến mãi vẫn giữ nguyên, không có gì thay đổi
        LocalDate today = LocalDate.now();
        Promotion activePromotion = product.getPromotions().stream()
                .filter(p -> p.isActive() && !today.isBefore(p.getStartDate()) && !today.isAfter(p.getEndDate()))
                .findFirst()
                .orElse(null);

        if (activePromotion != null) {
            double originalPrice = product.getSalePrice();
            double discount = originalPrice * activePromotion.getDiscountPercentage() / 100.0;
            response.put("salePrice", originalPrice - discount);
            response.put("discountPercentage", activePromotion.getDiscountPercentage());
        } else {
            response.put("salePrice", product.getSalePrice());
        }

        return ResponseEntity.ok(response);
    }
}