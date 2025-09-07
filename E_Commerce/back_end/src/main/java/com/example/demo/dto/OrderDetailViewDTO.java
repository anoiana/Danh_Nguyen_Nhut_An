package com.example.demo.dto;
import java.time.LocalDateTime;
import java.util.List; // Sử dụng List thay vì Set ở DTO để đảm bảo thứ tự

public class OrderDetailViewDTO {
    private Long id;
    private LocalDateTime orderDate;
    private String status;
    private String customerName;
    private String fullAddress;
    private List<OrderItemViewDTO> items; // <-- Đổi thành List
    private Double totalAmount;
    // Thêm các trường khác nếu cần
    private String email;
    private String phoneNumber;
    private String note;
    private String paymentMethod;
    private String paymentStatus;
    private Double subtotal;
    private Double shippingFee;
    private String couponCode;
    private Double discountAmount;

    public OrderDetailViewDTO() {} // Constructor rỗng

    // Getters and Setters cho TẤT CẢ các trường
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public LocalDateTime getOrderDate() { return orderDate; }
    public void setOrderDate(LocalDateTime orderDate) { this.orderDate = orderDate; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }
    public String getFullAddress() { return fullAddress; }
    public void setFullAddress(String fullAddress) { this.fullAddress = fullAddress; }
    public List<OrderItemViewDTO> getItems() { return items; }
    public void setItems(List<OrderItemViewDTO> items) { this.items = items; }
    public Double getTotalAmount() { return totalAmount; }
    public void setTotalAmount(Double totalAmount) { this.totalAmount = totalAmount; }
    //... thêm các getter/setter còn lại

    public String getCouponCode() { return couponCode; }
    public void setCouponCode(String couponCode) { this.couponCode = couponCode; }
    public Double getDiscountAmount() { return discountAmount; }
    public void setDiscountAmount(Double discountAmount) { this.discountAmount = discountAmount; }
    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }

    public String getPaymentMethod() {
        return paymentMethod;
    }

    public void setPaymentMethod(String paymentMethod) {
        this.paymentMethod = paymentMethod;
    }

    public String getPaymentStatus() {
        return paymentStatus;
    }

    public void setPaymentStatus(String paymentStatus) {
        this.paymentStatus = paymentStatus;
    }

    public Double getSubtotal() {
        return subtotal;
    }

    public void setSubtotal(Double subtotal) {
        this.subtotal = subtotal;
    }

    public Double getShippingFee() {
        return shippingFee;
    }

    public void setShippingFee(Double shippingFee) {
        this.shippingFee = shippingFee;
    }
}