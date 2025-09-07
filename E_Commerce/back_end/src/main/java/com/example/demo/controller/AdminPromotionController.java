// Trong package com.example.demo.controller
package com.example.demo.controller;

import com.example.demo.dto.PromotionDTO;
import com.example.demo.model.Product;
import com.example.demo.model.Promotion;
import com.example.demo.repository.ProductRepository;
import com.example.demo.repository.PromotionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/promotions")
@PreAuthorize("hasRole('ADMIN')")
public class AdminPromotionController {

    @Autowired private PromotionRepository promotionRepository;
    @Autowired private ProductRepository productRepository;

    @GetMapping
    public ResponseEntity<List<Promotion>> getAllPromotions() {
        return ResponseEntity.ok(promotionRepository.findAll());
    }

    @PostMapping
    @Transactional
    public ResponseEntity<Promotion> createPromotion(@RequestBody PromotionDTO promotionDTO) {
        Promotion promotion = new Promotion();
        updatePromotionFromDTO(promotion, promotionDTO);
        return ResponseEntity.ok(promotionRepository.save(promotion));
    }

    @PutMapping("/{id}")
    @Transactional
    public ResponseEntity<Promotion> updatePromotion(@PathVariable Long id, @RequestBody PromotionDTO promotionDTO) {
        Promotion promotion = promotionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Promotion not found"));
        updatePromotionFromDTO(promotion, promotionDTO);
        return ResponseEntity.ok(promotionRepository.save(promotion));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deletePromotion(@PathVariable Long id) {
        promotionRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    private void updatePromotionFromDTO(Promotion promotion, PromotionDTO dto) {
        promotion.setName(dto.getName());
        promotion.setDiscountPercentage(dto.getDiscountPercentage());
        promotion.setStartDate(dto.getStartDate());
        promotion.setEndDate(dto.getEndDate());
        promotion.setActive(dto.isActive());

        if (dto.getProductIds() != null) {
            List<Product> products = productRepository.findAllById(dto.getProductIds());
            promotion.setProducts(new HashSet<>(products));
        }
    }


    @GetMapping("/{id}")
    public ResponseEntity<PromotionDTO> getPromotionById(@PathVariable Long id) {
        Promotion promotion = promotionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Promotion not found"));
        return ResponseEntity.ok(convertToDTO(promotion));
    }

    private PromotionDTO convertToDTO(Promotion promotion) {
        PromotionDTO dto = new PromotionDTO();
        dto.setId(promotion.getId());
        dto.setName(promotion.getName());
        dto.setDiscountPercentage(promotion.getDiscountPercentage());
        dto.setStartDate(promotion.getStartDate());
        dto.setEndDate(promotion.getEndDate());
        dto.setActive(promotion.isActive());

        List<Long> productIds = promotion.getProducts().stream()
                .map(Product::getId)
                .collect(Collectors.toList());
        dto.setProductIds(productIds);

        return dto;
    }
}