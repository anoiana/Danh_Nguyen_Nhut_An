package com.example.demo.dto;

public class OrderItemViewDTO {

    private String productName;
    private String variantName;
    private String sizeName;
    private String imageUrl;
    private int quantity;
    private Double price;
    private Long productId;

    public OrderItemViewDTO() {} // Constructor rỗng

    // Getters
    public String getProductName() { return productName; }
    public String getVariantName() { return variantName; }
    public String getSizeName() { return sizeName; }
    public String getImageUrl() { return imageUrl; }
    public int getQuantity() { return quantity; }
    public Double getPrice() { return price; }

    // Setters
    public void setProductName(String productName) { this.productName = productName; }
    public void setVariantName(String variantName) { this.variantName = variantName; }
    public void setSizeName(String sizeName) { this.sizeName = sizeName; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
    public void setQuantity(int quantity) { this.quantity = quantity; }
    public void setPrice(Double price) { this.price = price; }
    public Long getProductId() { return productId; }
    public void setProductId(Long productId) { this.productId = productId; }
}