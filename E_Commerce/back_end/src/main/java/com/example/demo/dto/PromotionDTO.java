// Trong package com.example.demo.dto
package com.example.demo.dto;

import java.time.LocalDate;
import java.util.List;

public class PromotionDTO {
    private Long id;
    private String name;
    private int discountPercentage;
    private LocalDate startDate;
    private LocalDate endDate;
    private boolean isActive;
    private List<Long> productIds; // Danh sách ID các sản phẩm áp dụng

    public PromotionDTO() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getDiscountPercentage() {
        return discountPercentage;
    }

    public void setDiscountPercentage(int discountPercentage) {
        this.discountPercentage = discountPercentage;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }

    public LocalDate getEndDate() {
        return endDate;
    }

    public void setEndDate(LocalDate endDate) {
        this.endDate = endDate;
    }

    public boolean isActive() {
        return isActive;
    }

    public void setActive(boolean active) {
        isActive = active;
    }

    public List<Long> getProductIds() {
        return productIds;
    }

    public void setProductIds(List<Long> productIds) {
        this.productIds = productIds;
    }


    // Getters and Setters...
    // ...
}