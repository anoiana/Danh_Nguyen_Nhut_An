// Trong package com.example.demo.controller
package com.example.demo.controller;

import com.example.demo.dto.OrderDetailViewDTO;
import com.example.demo.dto.OrderListViewDTO;
import com.example.demo.model.Coupon;
import com.example.demo.model.Order;
import com.example.demo.model.OrderItem;
import com.example.demo.model.ProductSize;
import com.example.demo.repository.CouponRepository;
import com.example.demo.repository.OrderRepository;
import com.example.demo.repository.ProductSizeRepository;
import com.example.demo.security.services.UserDetailsImpl;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/user/orders") // Namespace riêng cho đơn hàng của user
public class UserOrderController {

    @Autowired private OrderRepository orderRepository;
    @Autowired private ProductSizeRepository productSizeRepository;
    @Autowired private CouponRepository couponRepository;

    @PutMapping("/{id}/cancel")
    @Transactional
    public ResponseEntity<?> cancelOrder(@PathVariable Long id) {
        // 1. Lấy thông tin người dùng đang đăng nhập
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
        Long userId = userDetails.getId();

        // 2. Tìm đơn hàng
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Không tìm thấy đơn hàng."));

        // 3. Kiểm tra quyền sở hữu
        if (!order.getUser().getId().equals(userId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Bạn không có quyền hủy đơn hàng này.");
        }

        // 4. Kiểm tra trạng thái đơn hàng
        if (!"PENDING".equalsIgnoreCase(order.getStatus())) {
            return ResponseEntity.badRequest().body("Chỉ có thể hủy đơn hàng ở trạng thái 'Chờ xác nhận'.");
        }

        // 5. Cập nhật trạng thái đơn hàng
        order.setStatus("CANCELED");

        // 6. [QUAN TRỌNG] Hoàn trả số lượng sản phẩm vào kho
        for (OrderItem item : order.getOrderItems()) {
            ProductSize productSize = productSizeRepository.findById(item.getSizeId())
                    .orElse(null); // Bỏ qua nếu size không còn tồn tại
            if (productSize != null) {
                productSize.setQuantityInStock(productSize.getQuantityInStock() + item.getQuantity());
                productSizeRepository.save(productSize);
            }
        }

        // (Tùy chọn) Hoàn trả lượt sử dụng coupon nếu có
        if (order.getCouponCode() != null && !order.getCouponCode().isEmpty()) {
            couponRepository.findByCode(order.getCouponCode()).ifPresent(coupon -> {
                coupon.setUsedCount(coupon.getUsedCount() - 1);
                couponRepository.save(coupon);
            });
        }

        orderRepository.save(order);

        return ResponseEntity.ok("Đã hủy đơn hàng thành công.");
    }
}