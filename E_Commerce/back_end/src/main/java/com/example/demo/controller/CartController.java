package com.example.demo.controller;

import com.example.demo.model.*;
import com.example.demo.repository.CartRepository;
import com.example.demo.repository.ProductRepository;
import com.example.demo.repository.UserRepository;
import com.example.demo.security.services.UserDetailsImpl;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional; // QUAN TRỌNG
import org.springframework.web.bind.annotation.*;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/cart")
public class CartController {

    @Autowired private CartRepository cartRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private ProductRepository productRepository;

    /**
     * Lấy giỏ hàng của người dùng đang đăng nhập.
     * Nếu chưa có giỏ hàng, một giỏ hàng mới sẽ được tạo.
     */
    @GetMapping
    @Transactional // Cần transactional để fetch các item
    public ResponseEntity<Cart> getUserCart() {
        Cart cart = getOrCreateCartForCurrentUser();
        return ResponseEntity.ok(cart);
    }

    /**
     * Thêm một sản phẩm vào giỏ hàng.
     * Nếu sản phẩm đã tồn tại (cùng variant và size), số lượng sẽ được cập nhật.
     */
    @PostMapping("/items")
    @Transactional
    public ResponseEntity<?> addItemToCart(@RequestBody CartItem newItemData) {
        try {
            Cart cart = getOrCreateCartForCurrentUser();

            Product product = productRepository.findByIdWithDetails(newItemData.getProductId())
                    .orElseThrow(() -> new EntityNotFoundException("Product not found"));

            Variant variant = product.getVariants().stream()
                    .filter(v -> v.getId().equals(newItemData.getVariantId())).findFirst()
                    .orElseThrow(() -> new EntityNotFoundException("Variant not found"));

            ProductSize size = variant.getSizes().stream()
                    .filter(s -> s.getId().equals(newItemData.getSizeId())).findFirst()
                    .orElseThrow(() -> new EntityNotFoundException("Size not found"));

            if (size.getQuantityInStock() < newItemData.getQuantity()) {
                return ResponseEntity.badRequest().body("Not enough stock available");
            }

            Optional<CartItem> existingItemOpt = cart.getItems().stream()
                    .filter(item -> item.getVariantId().equals(newItemData.getVariantId()) && item.getSizeId().equals(newItemData.getSizeId()))
                    .findFirst();

            if (existingItemOpt.isPresent()) {
                CartItem existingItem = existingItemOpt.get();
                existingItem.setQuantity(existingItem.getQuantity() + newItemData.getQuantity());
            } else {
                newItemData.setCart(cart);
                newItemData.setProductName(product.getName());
                newItemData.setVariantName(variant.getName());
                newItemData.setSizeName(size.getSizeName());
                newItemData.setImageUrl(variant.getImageUrl());
                newItemData.setPrice((variant.getVariantPrice() != null && variant.getVariantPrice() > 0) ? variant.getVariantPrice() : product.getSalePrice());
                cart.getItems().add(newItemData);
            }

            Cart updatedCart = cartRepository.save(cart);
            return ResponseEntity.ok(updatedCart);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * Cập nhật số lượng của một sản phẩm trong giỏ hàng.
     * Nếu số lượng mới <= 0, sản phẩm sẽ bị xóa.
     */
    @PutMapping("/items/{itemId}")
    @Transactional
    public ResponseEntity<Cart> updateItemQuantity(@PathVariable Long itemId, @RequestBody Map<String, Integer> payload) {
        Cart cart = getOrCreateCartForCurrentUser();
        CartItem itemToUpdate = cart.getItems().stream()
                .filter(item -> item.getId().equals(itemId))
                .findFirst()
                .orElseThrow(() -> new SecurityException("Cart item not found or does not belong to user"));

        int newQuantity = payload.get("quantity");

        if (newQuantity <= 0) {
            cart.getItems().remove(itemToUpdate);
        } else {
            // (Nâng cao) Có thể thêm kiểm tra tồn kho ở đây
            itemToUpdate.setQuantity(newQuantity);
        }

        Cart updatedCart = cartRepository.save(cart);
        return ResponseEntity.ok(updatedCart);
    }

    /**
     * Xóa một sản phẩm khỏi giỏ hàng.
     */
    @DeleteMapping("/items/{itemId}")
    @Transactional
    public ResponseEntity<Cart> removeItemFromCart(@PathVariable Long itemId) {
        Cart cart = getOrCreateCartForCurrentUser();
        boolean removed = cart.getItems().removeIf(item -> item.getId().equals(itemId));
        if (!removed) {
            throw new SecurityException("Cart item not found or does not belong to user");
        }
        Cart updatedCart = cartRepository.save(cart);
        return ResponseEntity.ok(updatedCart);
    }

    // =========================================================
    //                    HELPER METHODS
    // =========================================================

    /**
     * Lấy thông tin người dùng đang đăng nhập từ SecurityContext.
     * @return UserDetailsImpl của người dùng hiện tại.
     */
    private UserDetailsImpl getCurrentUserDetails() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || authentication.getPrincipal().equals("anonymousUser")) {
            throw new SecurityException("User is not authenticated");
        }
        return (UserDetailsImpl) authentication.getPrincipal();
    }

    /**
     * Lấy hoặc tạo giỏ hàng cho người dùng đang đăng nhập.
     * @return Giỏ hàng (Cart) của người dùng.
     */
    private Cart getOrCreateCartForCurrentUser() {
        UserDetailsImpl userDetails = getCurrentUserDetails();
        User currentUser = userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new EntityNotFoundException("User not found"));

        return cartRepository.findByUserId(currentUser.getId()).orElseGet(() -> {
            Cart newCart = new Cart();
            newCart.setUser(currentUser);
            return cartRepository.save(newCart);
        });
    }
}