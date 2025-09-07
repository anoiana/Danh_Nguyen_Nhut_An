package com.example.demo.controller;

import com.example.demo.dto.CreateOrderRequestDTO;
import com.example.demo.model.*;
import com.example.demo.repository.*;
import com.example.demo.security.services.UserDetailsImpl;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    @Autowired private OrderRepository orderRepository;
    @Autowired private CartRepository cartRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private ProductSizeRepository productSizeRepository;
    @Autowired private CouponRepository couponRepository;

    @PostMapping
    @Transactional
    public ResponseEntity<?> placeOrder(@RequestBody CreateOrderRequestDTO orderRequest) {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
            User currentUser = userRepository.findById(userDetails.getId())
                    .orElseThrow(() -> new EntityNotFoundException("User not found"));

            Cart cart = cartRepository.findByUserId(currentUser.getId())
                    .orElseThrow(() -> new RuntimeException("Cart is empty or not found"));

            if (cart.getItems().isEmpty()) {
                return ResponseEntity.badRequest().body("Cannot place order with an empty cart.");
            }
            
            currentUser.setPhoneNumber(orderRequest.getPhoneNumber());
            currentUser.setAddress(orderRequest.getShippingAddress());
            currentUser.setProvince(orderRequest.getShippingProvince());
            currentUser.setDistrict(orderRequest.getShippingDistrict());
            currentUser.setWard(orderRequest.getShippingWard());
            userRepository.save(currentUser);

            Order order = new Order();
            order.setUser(currentUser);
            order.setCustomerName(orderRequest.getCustomerName());
            order.setEmail(orderRequest.getEmail());
            order.setPhoneNumber(orderRequest.getPhoneNumber());
            order.setShippingAddress(orderRequest.getShippingAddress());
            order.setShippingProvince(orderRequest.getShippingProvince());
            order.setShippingDistrict(orderRequest.getShippingDistrict());
            order.setShippingWard(orderRequest.getShippingWard());
            order.setNote(orderRequest.getNote());
            order.setPaymentMethod(orderRequest.getPaymentMethod());
            order.setOrderDate(LocalDateTime.now());
            order.setStatus("PENDING");
            order.setPaymentStatus("UNPAID");

            Set<OrderItem> orderItems = new HashSet<>();
            double subtotal = 0;
            for (CartItem cartItem : cart.getItems()) {
                OrderItem orderItem = new OrderItem();
                orderItem.setOrder(order);
                orderItem.setProductId(cartItem.getProductId());
                orderItem.setVariantId(cartItem.getVariantId());
                orderItem.setSizeId(cartItem.getSizeId());
                orderItem.setProductName(cartItem.getProductName());
                orderItem.setVariantName(cartItem.getVariantName());
                orderItem.setSizeName(cartItem.getSizeName());
                orderItem.setImageUrl(cartItem.getImageUrl());
                orderItem.setPrice(cartItem.getPrice());
                orderItem.setQuantity(cartItem.getQuantity());

                orderItems.add(orderItem);
                subtotal += cartItem.getPrice() * cartItem.getQuantity();

                ProductSize productSize = productSizeRepository.findById(cartItem.getSizeId())
                        .orElseThrow(() -> new EntityNotFoundException("Product size not found for ID: " + cartItem.getSizeId()));
                if (productSize.getQuantityInStock() < cartItem.getQuantity()) {
                    throw new RuntimeException("Not enough stock for: " + cartItem.getProductName());
                }
                productSize.setQuantityInStock(productSize.getQuantityInStock() - cartItem.getQuantity());
                productSizeRepository.save(productSize);
            }
            order.setOrderItems(orderItems);
            order.setSubtotal(subtotal);

            double discountAmount = 0;
            String couponCode = orderRequest.getCouponCode();

            if (couponCode != null && !couponCode.trim().isEmpty()) {
                Coupon coupon = couponRepository.findByCode(couponCode)
                        .orElseThrow(() -> new RuntimeException("Invalid coupon code."));

                if (!coupon.isActive() || coupon.getExpiryDate().isBefore(LocalDate.now()) || coupon.getUsedCount() >= coupon.getQuantity()) {
                    throw new RuntimeException("Coupon code has expired or is out of stock.");
                }

                if (coupon.getType() == CouponType.PERCENTAGE) {
                    discountAmount = subtotal * (coupon.getValue() / 100.0);
                } else {
                    discountAmount = coupon.getValue();
                }
                
                coupon.setUsedCount(coupon.getUsedCount() + 1);
                couponRepository.save(coupon);
                order.setCouponCode(couponCode);
            }
            order.setDiscountAmount(discountAmount);
            
            Double shippingFee = orderRequest.getShippingFee() != null ? orderRequest.getShippingFee() : 0.0;
            double totalAmount = subtotal - discountAmount + shippingFee;
            if (totalAmount < 0) totalAmount = 0;

            order.setShippingFee(shippingFee);
            order.setTotalAmount(totalAmount);

            Order savedOrder = orderRepository.save(order);
         
            cart.getItems().clear();
            cartRepository.save(cart);

            return ResponseEntity.ok(savedOrder);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}