package com.example.demo.controller;

import com.example.demo.model.Coupon;
import com.example.demo.repository.CouponRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/coupons")
@PreAuthorize("hasRole('ADMIN')")
public class CouponAdminController {

    @Autowired
    private CouponRepository couponRepository;

    /**
     * Lấy tất cả các mã giảm giá.
     */
    @GetMapping
    public List<Coupon> getAllCoupons() {
        return couponRepository.findAll();
    }

    /**
     * Lấy chi tiết một mã giảm giá bằng ID.
     */
    @GetMapping("/{id}")
    public ResponseEntity<Coupon> getCouponById(@PathVariable Long id) {
        return couponRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Tạo một mã giảm giá mới.
     */
    @PostMapping
    public ResponseEntity<?> createCoupon(@RequestBody Coupon coupon) {
        // Kiểm tra xem mã đã tồn tại chưa
        if (couponRepository.findByCode(coupon.getCode()).isPresent()) {
            return ResponseEntity.badRequest().body("Error: Coupon code already exists!");
        }
        Coupon savedCoupon = couponRepository.save(coupon);
        return ResponseEntity.ok(savedCoupon);
    }

    /**
     * Cập nhật một mã giảm giá đã có.
     */
    @PutMapping("/{id}")
    public ResponseEntity<Coupon> updateCoupon(@PathVariable Long id, @RequestBody Coupon couponDetails) {
        return couponRepository.findById(id)
                .map(coupon -> {
                    coupon.setCode(couponDetails.getCode());
                    coupon.setDescription(couponDetails.getDescription());
                    coupon.setType(couponDetails.getType());
                    coupon.setValue(couponDetails.getValue());
                    coupon.setQuantity(couponDetails.getQuantity());
                    coupon.setExpiryDate(couponDetails.getExpiryDate());
                    coupon.setActive(couponDetails.isActive());
                    // usedCount không nên được cập nhật từ đây
                    return ResponseEntity.ok(couponRepository.save(coupon));
                }).orElse(ResponseEntity.notFound().build());
    }

    /**
     * Xóa một mã giảm giá.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteCoupon(@PathVariable Long id) {
        return couponRepository.findById(id)
                .map(coupon -> {
                    couponRepository.delete(coupon);
                    return ResponseEntity.ok().build();
                }).orElse(ResponseEntity.notFound().build());
    }
}