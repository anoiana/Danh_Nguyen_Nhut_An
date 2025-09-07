package com.example.demo.controller;

import com.example.demo.dto.*;
import com.example.demo.model.Order;
import com.example.demo.model.OrderItem;
import com.example.demo.model.User;
import com.example.demo.repository.OrderRepository;
import com.example.demo.repository.UserRepository;
import com.example.demo.security.services.UserDetailsImpl;
import com.example.demo.service.ImageUploadService;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@RestController
@RequestMapping("/api/user")
public class UserController {

    @Autowired private UserRepository userRepository;
    @Autowired private OrderRepository orderRepository;
    @Autowired private PasswordEncoder passwordEncoder;
    @Autowired
    private ImageUploadService imageUploadService;

    /**
     * Lấy thông tin hồ sơ cá nhân của người dùng đang đăng nhập.
     */
    @GetMapping("/me")
    public ResponseEntity<CustomerListDTO.UserProfileDTO> getCurrentUserProfile() {
        User currentUser = getCurrentUserEntity();
        CustomerListDTO.UserProfileDTO profileDTO = convertUserToProfileDTO(currentUser);
        return ResponseEntity.ok(profileDTO);
    }

    /**
     * Cập nhật thông tin hồ sơ của người dùng đang đăng nhập.
     */
    @PutMapping("/me")
    @Transactional
    public ResponseEntity<?> updateCurrentUserProfile(@RequestBody CustomerListDTO.UpdateProfileRequestDTO profileData) {
        User currentUser = getCurrentUserEntity();

        currentUser.setUsername(profileData.getUsername());
        currentUser.setPhoneNumber(profileData.getPhoneNumber());
        currentUser.setAddress(profileData.getAddress());
        currentUser.setProvince(profileData.getProvince());
        currentUser.setDistrict(profileData.getDistrict());
        currentUser.setWard(profileData.getWard());

        userRepository.save(currentUser);
        return ResponseEntity.ok("Profile updated successfully.");
    }


    @PutMapping("/change-password")
    @Transactional
    public ResponseEntity<?> changePassword(@RequestBody CreateOrderRequestDTO.ChangePasswordRequestDTO passwordRequest) {
        if (passwordRequest.getNewPassword() == null || passwordRequest.getNewPassword().length() < 6) {
            return ResponseEntity.badRequest().body("New password must be at least 6 characters long.");
        }
        if (!passwordRequest.getNewPassword().equals(passwordRequest.getConfirmPassword())) {
            return ResponseEntity.badRequest().body("New password and confirmation do not match.");
        }

        User currentUser = getCurrentUserEntity();

        if (!passwordEncoder.matches(passwordRequest.getCurrentPassword(), currentUser.getPassword())) {
            return ResponseEntity.badRequest().body("Current password is incorrect.");
        }

        currentUser.setPassword(passwordEncoder.encode(passwordRequest.getNewPassword()));
        userRepository.save(currentUser);

        return ResponseEntity.ok("Password changed successfully.");
    }

    /**
     * Lấy lịch sử đơn hàng của người dùng đang đăng nhập.
     */
    @GetMapping("/orders")
    @Transactional(readOnly = true)
    public ResponseEntity<List<OrderListViewDTO>> getMyOrderHistory() {
        User currentUser = getCurrentUserEntity();
        List<Order> orders = orderRepository.findByUserIdOrderByOrderDateDesc(currentUser.getId());

        List<OrderListViewDTO> orderDTOs = orders.stream()
                .map(this::convertToOrderListViewDTO)
                .collect(Collectors.toList());

        return ResponseEntity.ok(orderDTOs);
    }


    @GetMapping("/orders/{orderId}")
    @Transactional(readOnly = true)
    public ResponseEntity<OrderDetailViewDTO> getMyOrderDetail(@PathVariable Long orderId) {
        User currentUser = getCurrentUserEntity();

        Order order = orderRepository.findByIdWithItems(orderId)
                .orElseThrow(() -> new EntityNotFoundException("Order not found"));

        if (order.getUser() == null || !order.getUser().getId().equals(currentUser.getId())) {
            throw new SecurityException("You are not authorized to view this order.");
        }

        OrderDetailViewDTO dto = convertToDetailViewDTO(order);
        return ResponseEntity.ok(dto);
    }

    private User getCurrentUserEntity() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
        return userRepository.findById(userDetails.getId())
                .orElseThrow(() -> new EntityNotFoundException("User not found with ID: " + userDetails.getId()));
    }

    private CustomerListDTO.UserProfileDTO convertUserToProfileDTO(User user) {
        CustomerListDTO.UserProfileDTO dto = new CustomerListDTO.UserProfileDTO();
        dto.setId(user.getId());
        dto.setUsername(user.getUsername());
        dto.setEmail(user.getEmail());
        dto.setPhoneNumber(user.getPhoneNumber());
        dto.setAddress(user.getAddress());
        dto.setProvince(user.getProvince());
        dto.setDistrict(user.getDistrict());
        dto.setWard(user.getWard());
        dto.setAvatarUrl(user.getAvatarUrl());
        return dto;
    }

    private OrderListViewDTO convertToOrderListViewDTO(Order order) {
        OrderListViewDTO dto = new OrderListViewDTO();
        dto.setId(order.getId());
        dto.setCustomerName(order.getCustomerName());
        dto.setOrderDate(order.getOrderDate());
        dto.setTotalAmount(order.getTotalAmount());
        dto.setStatus(order.getStatus());
        return dto;
    }

    private OrderDetailViewDTO convertToDetailViewDTO(Order order) {
        OrderDetailViewDTO dto = new OrderDetailViewDTO();
        dto.setId(order.getId());
        dto.setOrderDate(order.getOrderDate());
        dto.setStatus(order.getStatus());
        dto.setPaymentMethod(order.getPaymentMethod());
        dto.setPaymentStatus(order.getPaymentStatus());
        dto.setCustomerName(order.getCustomerName());
        dto.setEmail(order.getEmail());
        dto.setPhoneNumber(order.getPhoneNumber());
        dto.setNote(order.getNote());
        dto.setTotalAmount(order.getTotalAmount());
        dto.setShippingFee(order.getShippingFee());
        dto.setCouponCode(order.getCouponCode());
        dto.setDiscountAmount(order.getDiscountAmount());

        String fullAddress = Stream.of(
                        order.getShippingAddress(),
                        order.getShippingWard(),
                        order.getShippingDistrict(),
                        order.getShippingProvince()
                )
                .filter(s -> s != null && !s.trim().isEmpty())
                .collect(Collectors.joining(", "));
        dto.setFullAddress(fullAddress);

        if (order.getOrderItems() != null) {
            List<OrderItemViewDTO> itemDTOs = order.getOrderItems().stream()
                    .map(this::convertOrderItemToDTO)
                    .collect(Collectors.toList());
            dto.setItems(itemDTOs);

            double subtotal = itemDTOs.stream()
                    .mapToDouble(item -> item.getPrice() * item.getQuantity())
                    .sum();
            dto.setSubtotal(subtotal);
        } else {
            dto.setItems(Collections.emptyList());
            dto.setSubtotal(0.0);
        }

        return dto;
    }

    private OrderItemViewDTO convertOrderItemToDTO(OrderItem item) {
        OrderItemViewDTO dto = new OrderItemViewDTO();
        dto.setProductId(item.getProductId());
        dto.setProductName(item.getProductName());
        dto.setVariantName(item.getVariantName());
        dto.setSizeName(item.getSizeName());
        dto.setImageUrl(item.getImageUrl());
        dto.setQuantity(item.getQuantity());
        dto.setPrice(item.getPrice());
        return dto;
    }

    @PostMapping("/avatar")
    @Transactional
    public ResponseEntity<?> uploadAvatar(@RequestParam("file") MultipartFile file) {
        try {
            User currentUser = getCurrentUserEntity();
            String imageUrl = imageUploadService.uploadFile(file);
            currentUser.setAvatarUrl(imageUrl);
            userRepository.save(currentUser);
            return ResponseEntity.ok(Map.of("avatarUrl", imageUrl));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.badRequest().body("Failed to upload avatar: " + e.getMessage());
        }
    }
}