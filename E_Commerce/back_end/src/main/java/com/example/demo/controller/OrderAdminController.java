package com.example.demo.controller;

import com.example.demo.dto.OrderDetailViewDTO;
import com.example.demo.dto.OrderItemViewDTO;
import com.example.demo.dto.OrderListViewDTO;
import com.example.demo.model.Order;
import com.example.demo.model.OrderItem;
import com.example.demo.repository.OrderRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/orders")
@PreAuthorize("hasRole('ADMIN')")
public class OrderAdminController {

    @Autowired
    private OrderRepository orderRepository;

    /**
     * Lấy danh sách tóm tắt của tất cả các đơn hàng, sắp xếp theo ngày mới nhất.
     * @return Danh sách các OrderListViewDTO.
     */
    @GetMapping
    @Transactional(readOnly = true)
    public ResponseEntity<List<OrderListViewDTO>> getAllOrders() {
        List<Order> orders = orderRepository.findAll(Sort.by(Sort.Direction.DESC, "orderDate"));

        List<OrderListViewDTO> dtos = orders.stream()
                .map(this::convertToListViewDTO)
                .collect(Collectors.toList());

        return ResponseEntity.ok(dtos);
    }

    /**
     * Lấy thông tin chi tiết đầy đủ của một đơn hàng bằng ID.
     * @param id ID của đơn hàng.
     * @return Chi tiết đơn hàng dưới dạng OrderDetailViewDTO.
     */
    @GetMapping("/{id}")
    @Transactional(readOnly = true)
    public ResponseEntity<OrderDetailViewDTO> getOrderDetails(@PathVariable Long id) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Order not found with id: " + id));

        OrderDetailViewDTO dto = convertToDetailViewDTO(order);

        return ResponseEntity.ok(dto);
    }

    /**
     * Lấy lịch sử đơn hàng (dạng tóm tắt) của một người dùng cụ thể.
     * @param userId ID của người dùng.
     * @return Danh sách các OrderListViewDTO.
     */
    @GetMapping("/user/{userId}")
    @Transactional(readOnly = true)
    public ResponseEntity<List<OrderListViewDTO>> getOrdersByUserId(@PathVariable Long userId) {
        List<Order> orders = orderRepository.findByUserIdOrderByOrderDateDesc(userId);

        List<OrderListViewDTO> dtos = orders.stream()
                .map(this::convertToListViewDTO)
                .collect(Collectors.toList());

        return ResponseEntity.ok(dtos);
    }

    /**
     * Cập nhật trạng thái của một đơn hàng.
     * @param id ID của đơn hàng.
     * @param payload JSON chứa trạng thái mới, ví dụ: {"status": "SHIPPED"}.
     * @return ResponseEntity rỗng với status 200 OK.
     */
    @PutMapping("/{id}/status")
    @Transactional
    public ResponseEntity<?> updateOrderStatus(@PathVariable Long id, @RequestBody Map<String, String> payload) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Order not found with id: " + id));

        String newStatus = payload.get("status");
        if (newStatus == null || newStatus.trim().isEmpty()) {
            return ResponseEntity.badRequest().body("New status cannot be empty.");
        }

        order.setStatus(newStatus.toUpperCase());
        orderRepository.save(order);

        return ResponseEntity.ok().build();
    }

    // =========================================================
    //         CÁC HÀM HELPER ĐỂ CHUYỂN ĐỔI ENTITY -> DTO
    // =========================================================

    private OrderListViewDTO convertToListViewDTO(Order order) {
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
        String fullAddress = String.join(", ",
                order.getShippingAddress(),
                order.getShippingWard(),
                order.getShippingDistrict(),
                order.getShippingProvince()
        );
        dto.setFullAddress(fullAddress);

        List<OrderItemViewDTO> itemDTOs = order.getOrderItems().stream()
                .map(this::convertOrderItemToDTO)
                .collect(Collectors.toList());
        dto.setItems(itemDTOs);

        double subtotal = itemDTOs.stream()
                .mapToDouble(item -> item.getPrice() * item.getQuantity())
                .sum();
        dto.setSubtotal(subtotal);

        return dto;
    }

    private OrderItemViewDTO convertOrderItemToDTO(OrderItem item) {
        OrderItemViewDTO dto = new OrderItemViewDTO();
        dto.setProductName(item.getProductName());
        dto.setVariantName(item.getVariantName());
        dto.setProductId(item.getProductId());
        dto.setSizeName(item.getSizeName());
        dto.setImageUrl(item.getImageUrl());
        dto.setQuantity(item.getQuantity());
        dto.setPrice(item.getPrice());
        return dto;
    }
}