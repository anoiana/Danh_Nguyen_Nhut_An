package com.example.demo.controller;

import com.example.demo.dto.ProductAdminListDTO;
import com.example.demo.model.Category;
import com.example.demo.model.Product;
import com.example.demo.model.Promotion;
import com.example.demo.model.Variant;
import com.example.demo.repository.CategoryRepository;
import com.example.demo.repository.ProductRepository;
import com.example.demo.service.ImageUploadService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/products")
@PreAuthorize("hasRole('ADMIN')")
public class ProductAdminController {

    @Autowired private ProductRepository productRepository;
    @Autowired private CategoryRepository categoryRepository;
    @Autowired private ImageUploadService imageUploadService;
    @Autowired private ObjectMapper objectMapper;

    /**
     * API lấy danh sách tóm tắt tất cả sản phẩm để hiển thị trong bảng admin.
     */
    @GetMapping
    @Transactional(readOnly = true)
    public ResponseEntity<List<ProductAdminListDTO>> getAllProductsForAdmin() {
        List<Product> products = productRepository.findAll();
        List<ProductAdminListDTO> dtos = products.stream()
                .map(this::convertToAdminListDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * API lấy chi tiết MỘT sản phẩm, bao gồm cả các biến thể và size.
     * Trả về Entity đầy đủ để điền vào form chỉnh sửa.
     */
    @GetMapping("/{id}")
    public ResponseEntity<Product> getProductById(@PathVariable Long id) {
        // Sử dụng findByIdWithDetails để fetch join các collection, tránh lỗi LazyInitializationException
        return productRepository.findByIdWithDetails(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * API tạo một sản phẩm mới với thư viện nhiều ảnh.
     */
    @PostMapping
    @Transactional
    public ResponseEntity<?> addProduct(@RequestParam("productData") String productDataJson,
                                        // THAY ĐỔI: Nhận danh sách file ảnh chính
                                        @RequestParam("mainImages") List<MultipartFile> mainImages,
                                        // THAY ĐỔI: Nhận danh sách file ảnh biến thể (có thể không có)
                                        @RequestParam(value = "variantImages", required = false) List<MultipartFile> variantImages) {
        try {
            Product product = objectMapper.readValue(productDataJson, Product.class);

            Category category = categoryRepository.findById(product.getCategory().getId())
                    .orElseThrow(() -> new EntityNotFoundException("Category not found"));
            product.setCategory(category);

            // === LOGIC XỬ LÝ ẢNH MỚI ===
            // 1. Xử lý thư viện ảnh chính
            if (mainImages == null || mainImages.isEmpty()) {
                return ResponseEntity.badRequest().body("Vui lòng cung cấp ít nhất một ảnh chính.");
            }
            List<String> mainImageUrls = new ArrayList<>();
            for (MultipartFile imageFile : mainImages) {
                mainImageUrls.add(imageUploadService.uploadFile(imageFile));
            }
            product.setImageUrls(mainImageUrls); // Gán danh sách URL vào sản phẩm

            // 2. Xử lý ảnh biến thể
            int variantImageIndex = 0;
            if (product.getVariants() != null && !product.getVariants().isEmpty()) {
                for (Variant variant : product.getVariants()) {
                    if (variantImages != null && variantImageIndex < variantImages.size()) {
                        variant.setImageUrl(imageUploadService.uploadFile(variantImages.get(variantImageIndex++)));
                    } else {
                        variant.setImageUrl(null); // Hoặc một URL ảnh placeholder
                    }
                }
            }
            // === KẾT THÚC LOGIC XỬ LÝ ẢNH ===

            // Thiết lập mối quan hệ 2 chiều
            product.getVariants().forEach(variant -> {
                variant.setProduct(product);
                variant.getSizes().forEach(size -> size.setVariant(variant));
            });

            Product savedProduct = productRepository.save(product);
            return ResponseEntity.ok(savedProduct);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.badRequest().body("Error creating product: " + e.getMessage());
        }
    }

    /**
     * API cập nhật một sản phẩm đã có.
     */
    @PutMapping("/{id}")
    @Transactional
    public ResponseEntity<?> updateProduct(@PathVariable Long id,
                                           @RequestParam("productData") String productDataJson,
                                           // THAY ĐỔI: Nhận các file ảnh chính MỚI được tải lên
                                           @RequestParam(value = "newMainImages", required = false) List<MultipartFile> newMainImages,
                                           // THAY ĐỔI: Nhận các file ảnh biến thể MỚI được tải lên
                                           @RequestParam(value = "newVariantImages", required = false) List<MultipartFile> newVariantImages) {

        Product existingProduct = productRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Product not found with id: " + id));

        try {
            Product updatedProductData = objectMapper.readValue(productDataJson, Product.class);

            // Cập nhật thông tin cơ bản
            existingProduct.setName(updatedProductData.getName());
            existingProduct.setDescription(updatedProductData.getDescription());
            existingProduct.setCategory(updatedProductData.getCategory());
            existingProduct.setImportPrice(updatedProductData.getImportPrice());
            existingProduct.setSalePrice(updatedProductData.getSalePrice());

            // === LOGIC CẬP NHẬT ẢNH MỚI ===
            // 1. Cập nhật thư viện ảnh chính
            // Lấy danh sách URL của các ảnh cũ mà người dùng muốn giữ lại (được gửi trong JSON)
            List<String> finalImageUrls = new ArrayList<>(updatedProductData.getImageUrls());

            // Tải các file ảnh MỚI lên và thêm URL vào danh sách
            if (newMainImages != null && !newMainImages.isEmpty()) {
                for (MultipartFile imageFile : newMainImages) {
                    finalImageUrls.add(imageUploadService.uploadFile(imageFile));
                }
            }
            existingProduct.setImageUrls(finalImageUrls); // Gán lại danh sách ảnh cuối cùng

            // 2. Cập nhật biến thể và ảnh của chúng (theo chiến lược xóa cũ thêm mới)
            existingProduct.getVariants().clear();
            productRepository.saveAndFlush(existingProduct); // Áp dụng việc xóa ngay lập tức

            int newVariantImageIndex = 0;
            for (Variant newVariantData : updatedProductData.getVariants()) {
                // Nếu newVariantData không có imageUrl (frontend gửi lên là "" hoặc null),
                // nghĩa là người dùng đã chọn một ảnh mới cho nó.
                if ((newVariantData.getImageUrl() == null || newVariantData.getImageUrl().isEmpty())
                        && newVariantImages != null && newVariantImageIndex < newVariantImages.size()) {
                    newVariantData.setImageUrl(imageUploadService.uploadFile(newVariantImages.get(newVariantImageIndex++)));
                }
                // Ngược lại, nếu nó có imageUrl, tức là người dùng giữ lại ảnh cũ,
                // giá trị này đã được gán sẵn khi deserialize JSON.

                newVariantData.setProduct(existingProduct);
                newVariantData.getSizes().forEach(size -> size.setVariant(newVariantData));
                existingProduct.getVariants().add(newVariantData);
            }
            // === KẾT THÚC LOGIC CẬP NHẬT ẢNH ===

            Product savedProduct = productRepository.save(existingProduct);
            return ResponseEntity.ok(savedProduct);

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.badRequest().body("Error updating product: " + e.getMessage());
        }
    }

    @DeleteMapping("/{id}")
    @Transactional
    public ResponseEntity<?> deleteProduct(@PathVariable Long id) {
        Product product = productRepository.findById(id)
                .orElse(null);

        if (product == null) {
            return ResponseEntity.notFound().build();
        }

        for (Promotion promotion : new ArrayList<>(product.getPromotions())) {
            promotion.getProducts().remove(product);
        }

        productRepository.delete(product);
        return ResponseEntity.ok().build();
    }

    private ProductAdminListDTO convertToAdminListDTO(Product product) {
        ProductAdminListDTO dto = new ProductAdminListDTO();
        dto.setId(product.getId());
        dto.setName(product.getName());
        dto.setImageUrl(product.getPrimaryImageUrl());
        dto.setSalePrice(product.getSalePrice());
        if (product.getCategory() != null) {
            dto.setCategoryName(product.getCategory().getName());
        } else {
            dto.setCategoryName("N/A");
        }
        return dto;
    }
}