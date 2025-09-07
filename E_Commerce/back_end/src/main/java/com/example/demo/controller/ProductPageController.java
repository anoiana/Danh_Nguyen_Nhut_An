// Tạo file mới ProductPageController.java nếu chưa có, hoặc thêm vào controller có sẵn
package com.example.demo.controller;

// ... các import khác
import com.example.demo.dto.ProductCardDTO;
import com.example.demo.model.Product;
import com.example.demo.repository.ProductRepository;
import com.example.demo.service.ProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable; // Thêm import
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/products-page")
public class ProductPageController {
    @Autowired
    private ProductRepository productRepository;
    @Autowired private ProductService productService;

    @GetMapping("/all")
    public ResponseEntity<Page<ProductCardDTO>> getAllProducts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "12") int size) {

        Pageable pageable = PageRequest.of(page, size, Sort.by("id").descending());
        Page<Product> productPage = productRepository.findAllProducts(pageable);
        Page<ProductCardDTO> dtoPage = productPage.map(productService::convertToProductCardDTO);
        return ResponseEntity.ok(dtoPage);
    }

    @GetMapping("/promotional")
    public ResponseEntity<Page<ProductCardDTO>> getPromotionalProducts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "12") int size) {

        Pageable pageable = PageRequest.of(page, size);
        Page<Product> productPage = productRepository.findActivePromotionalProducts(pageable);
        Page<ProductCardDTO> dtoPage = productPage.map(productService::convertToProductCardDTO);
        return ResponseEntity.ok(dtoPage);
    }

    @GetMapping("/{productId}/related")
    public ResponseEntity<Page<ProductCardDTO>> getRelatedProducts(
            @PathVariable Long productId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "5") int size) { // Size mặc định là 4

        Product currentProduct = productRepository.findById(productId)
                .orElseThrow(() -> new RuntimeException("Product not found"));

        Long categoryId = currentProduct.getCategory().getId();
        Pageable pageable = PageRequest.of(page, size);

        Page<Product> relatedProductPage = productRepository.findByCategoryIdAndIdNot(categoryId, productId, pageable);

        Page<ProductCardDTO> dtoPage = relatedProductPage.map(productService::convertToProductCardDTO);

        return ResponseEntity.ok(dtoPage);
    }
}