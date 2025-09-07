// Trong package com.example.demo.controller, tạo file mới CategoryPageController.java
package com.example.demo.controller;

import com.example.demo.dto.ProductCardDTO;
import com.example.demo.model.Category;
import com.example.demo.model.Product;
import com.example.demo.repository.CategoryRepository;
import com.example.demo.repository.ProductRepository;
import com.example.demo.service.ProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/categories")
public class CategoryPageController {

    @Autowired private CategoryRepository categoryRepository;
    @Autowired private ProductRepository productRepository;
    @Autowired private ProductService productService;

    // API chính cho trang danh sách sản phẩm theo category
    @GetMapping("/{id}/products")
    public ResponseEntity<Map<String, Object>> getCategoryPageData(
            @PathVariable Long id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "12") int size) {

        // 1. Lấy thông tin category
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Category not found"));

        // 2. Lấy danh sách sản phẩm đã phân trang
        Pageable pageable = PageRequest.of(page, size);
        Page<Product> productPage = productRepository.findByCategoryId(id, pageable);
        Page<ProductCardDTO> dtoPage = productPage.map(productService::convertToProductCardDTO);

        // 3. Đóng gói tất cả vào một Map để trả về
        Map<String, Object> response = new HashMap<>();
        response.put("category", category); // Trả về thông tin category
        response.put("productPage", dtoPage);  // Trả về đối tượng Page

        return ResponseEntity.ok(response);
    }
}