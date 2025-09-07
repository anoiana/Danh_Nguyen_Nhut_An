package com.example.demo.dto;

import java.time.LocalDateTime;

public class OrderSummaryDTO {
    private Long id;
    private LocalDateTime orderDate;
    private Double totalAmount;
    private String status;

    // Constructors
    public OrderSummaryDTO() {}
    public OrderSummaryDTO(Long id, LocalDateTime orderDate, Double totalAmount, String status) {
        this.id = id;
        this.orderDate = orderDate;
        this.totalAmount = totalAmount;
        this.status = status;
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public LocalDateTime getOrderDate() { return orderDate; }
    public void setOrderDate(LocalDateTime orderDate) { this.orderDate = orderDate; }
    public Double getTotalAmount() { return totalAmount; }
    public void setTotalAmount(Double totalAmount) { this.totalAmount = totalAmount; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}