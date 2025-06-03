package com.springcommerce.springcommerce.entity;

import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;

@Entity
public class Cart {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idCart;

    private Long quantity;

    @OneToMany(mappedBy = "cart", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<CartProduct> cartProducts = new ArrayList<>();

    @OneToMany(mappedBy = "cart", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<CartCustomers> cartCustomers = new ArrayList<>();

    // Getters và Setters
    public Long getIdCart() {
        return idCart;
    }

    public void setIdCart(Long idCart) {
        this.idCart = idCart;
    }

    public Long getQuantity() {
        return quantity;
    }

    public void setQuantity(Long quantity) {
        this.quantity = quantity;
    }

    public List<CartProduct> getCartProducts() {
        return cartProducts;
    }

    public void setCartProducts(List<CartProduct> cartProducts) {
        this.cartProducts = cartProducts;
    }

    // Phương thức thêm sản phẩm vào giỏ
    public void addProduct(Product product) {
        // Kiểm tra nếu sản phẩm đã tồn tại trong giỏ thì không thêm lại
        for (CartProduct cartProduct : cartProducts) {
            if (cartProduct.getProduct().getProductId().equals(product.getProductId())) {
                return; // Nếu đã có, thoát
            }
        }

        // Nếu chưa tồn tại, thêm mới
        CartProduct newCartProduct = new CartProduct();
        newCartProduct.setCart(this);
        newCartProduct.setProduct(product);
        cartProducts.add(newCartProduct);
    }

    // Phương thức xóa sản phẩm khỏi giỏ hàng
    public void removeProduct(Long productId) {
        // Tìm và xóa CartProduct có liên kết với Product dựa trên productId
        cartProducts.removeIf(cartProduct -> cartProduct.getProduct().getProductId().equals(productId));
    }

    public List<CartCustomers> getCartCustomers() {
        return cartCustomers;
    }

    public void setCartCustomers(List<CartCustomers> cartCustomers) {
        this.cartCustomers = cartCustomers;
    }
}
