// Trong package com.example.demo.controller
package com.example.demo.controller;

import com.example.demo.dto.ProductCardDTO;
import com.example.demo.model.Category;
import com.example.demo.repository.CategoryRepository;
import com.example.demo.repository.ProductRepository;
import com.example.demo.service.ProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/home")
public class HomeController {

    @Autowired private ProductRepository productRepository;
    @Autowired private CategoryRepository categoryRepository;
    @Autowired private ProductService productService;

    // API chính để lấy tất cả dữ liệu cho trang chủ
    // Trong file HomeController.java
    // TRONG FILE: controller/HomeController.java

    @GetMapping("/data")
    public ResponseEntity<Map<String, Object>> getHomePageData() {
        Map<String, Object> response = new HashMap<>();

        // 1. Sản phẩm khuyến mãi
        List<ProductCardDTO> promotionalProducts = productService.convertToProductCardDTOList(
                productRepository.findActivePromotionalProducts(PageRequest.of(0, 8)).getContent()
        );
        response.put("promotionalProducts", promotionalProducts);

        // 2. Sản phẩm mới nhất
        List<ProductCardDTO> newProducts = productService.convertToProductCardDTOList(
                productRepository.findAll(PageRequest.of(0, 8, Sort.by("id").descending())).getContent()
        );
        response.put("newProducts", newProducts);

        List<Map<String, Object>> categorySections = new ArrayList<>();
        List<Category> categories = categoryRepository.findAll(PageRequest.of(0, 10)).getContent();

        for (Category category : categories) {
            List<ProductCardDTO> productsByCategory = productService.convertToProductCardDTOList(
                    productRepository.findByCategoryId(category.getId(), PageRequest.of(0, 8)).getContent() // Lấy 8 sản phẩm cho slider
            );

            // Chỉ thêm vào danh sách nếu category có sản phẩm
            if (!productsByCategory.isEmpty()) {
                Map<String, Object> categorySectionData = new HashMap<>();
                categorySectionData.put("categoryName", category.getName());
                categorySectionData.put("products", productsByCategory);
                categorySections.add(categorySectionData);
            }
        }

        response.put("categorySections", categorySections); // Đặt danh sách vào key "categorySections"

        return ResponseEntity.ok(response);
    }

    // API để lấy danh sách category cho header
    @GetMapping("/categories")
    public ResponseEntity<List<Category>> getCategoriesForHeader() {
        return ResponseEntity.ok(categoryRepository.findAll());
    }
}