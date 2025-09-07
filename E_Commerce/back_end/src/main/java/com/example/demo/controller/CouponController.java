package com.example.demo.controller;

import com.example.demo.model.Coupon;
import com.example.demo.repository.CouponRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;

@RestController
@RequestMapping("/api/coupons")
public class CouponController {

    @Autowired
    private CouponRepository couponRepository;

    /**
     * API công khai để kiểm tra một mã giảm giá.
     * @param code Mã code mà người dùng nhập.
     * @return Thông tin coupon nếu hợp lệ, ngược lại trả về lỗi.
     */
    @GetMapping("/validate/{code}")
    public ResponseEntity<?> validateCoupon(@PathVariable String code) {
        Coupon coupon = couponRepository.findByCode(code.toUpperCase())
                .orElse(null);

        if (coupon == null) {
            return ResponseEntity.badRequest().body("Mã giảm giá không tồn tại.");
        }
        if (!coupon.isActive() || coupon.getExpiryDate().isBefore(LocalDate.now()) || coupon.getUsedCount() >= coupon.getQuantity()) {
            return ResponseEntity.badRequest().body("Mã giảm giá đã hết hạn hoặc hết lượt sử dụng.");
        }

        // Trả về thông tin coupon (có thể dùng DTO để chỉ trả về các trường cần thiết)
        return ResponseEntity.ok(coupon);
    }
}