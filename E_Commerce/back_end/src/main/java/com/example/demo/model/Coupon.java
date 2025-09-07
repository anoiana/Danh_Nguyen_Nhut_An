package com.example.demo.model;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "coupons")
public class Coupon {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String code; // Mã giảm giá, ví dụ: "SALE50", "FREESHIP"

    private String description; // Mô tả ngắn

    @Enumerated(EnumType.STRING)
    private CouponType type; // Loại giảm giá: PERCENTAGE (phần trăm) hoặc FIXED_AMOUNT (số tiền cố định)

    private Double value; // Giá trị giảm (ví dụ: 50 cho 50%, hoặc 50000 cho 50k)

    private int quantity; // Số lượng mã có thể sử dụng

    private int usedCount; // Số lần đã sử dụng

    private LocalDate startDate; // Ngày bắt đầu hiệu lực
    private LocalDate expiryDate; // Ngày hết hạn

    private boolean active; // Trạng thái (đang hoạt động / đã khóa)

    // Enum cho CouponType

    public Coupon() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public CouponType getType() {
        return type;
    }

    public void setType(CouponType type) {
        this.type = type;
    }

    public Double getValue() {
        return value;
    }

    public void setValue(Double value) {
        this.value = value;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    public int getUsedCount() {
        return usedCount;
    }

    public void setUsedCount(int usedCount) {
        this.usedCount = usedCount;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }

    public LocalDate getExpiryDate() {
        return expiryDate;
    }

    public void setExpiryDate(LocalDate expiryDate) {
        this.expiryDate = expiryDate;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    // Getters and Setters for all fields...
}