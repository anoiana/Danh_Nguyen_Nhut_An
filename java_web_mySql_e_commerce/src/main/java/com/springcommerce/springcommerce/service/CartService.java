package com.springcommerce.springcommerce.service;

import com.springcommerce.springcommerce.Repository.CartProductRepository;
import com.springcommerce.springcommerce.Repository.CartRepository;
import com.springcommerce.springcommerce.entity.Cart;
import com.springcommerce.springcommerce.entity.CartProduct;
import com.springcommerce.springcommerce.entity.Product;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class CartService {

    @Autowired
    private CartRepository cartRepository;

    @Autowired
    private CartProductRepository cartProductRepository;

    public Cart getCart() {
        return cartRepository.findFirstByOrderByIdCartAsc().orElse(null);
    }

    public void saveCart(Cart cart) {
        cartRepository.save(cart);
    }

    public Cart getCurrentCartOrCreateNew() {
        Cart cart = getCart();
        if (cart == null) {
            cart = new Cart();
            cartRepository.save(cart);
        }
        return cart;
    }

    public void removeProductFromCart(Cart cart, Long productId) {
        // Tìm sản phẩm trong giỏ hàng
        cart.getCartProducts().removeIf(cartProduct -> cartProduct.getProduct().getProductId().equals(productId));

        // Lưu cập nhật vào cơ sở dữ liệu
        cartRepository.save(cart);
    }

    public void updateQuantity(Cart cart) {
        long totalQuantity = 0;
        for (CartProduct cartProduct : cart.getCartProducts()) {
            totalQuantity += cartProduct.getQuantity();
        }
        // Số lượng = tổng số CartProduct trong giỏ hàng
        cart.setQuantity(totalQuantity);

        saveCart(cart); // Lưu giỏ hàng sau khi cập nhật
    }

    public void updateProductQuantity(Long cartId, Long productId, int quantity) {
        // Lấy giỏ hàng từ database
        Cart cart = cartRepository.findById(cartId)
                .orElseThrow(() -> new RuntimeException("Cart not found"));

        // Tìm sản phẩm trong giỏ hàng
        CartProduct cartProduct = cart.getCartProducts().stream()
                .filter(cp -> cp.getProduct().getProductId().equals(productId))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("Product not found in cart"));

        // Cập nhật số lượng
        cartProduct.setQuantity(quantity);
        cart.setQuantity(cartProduct.getQuantity());
        // Lưu CartProduct
        cartProductRepository.save(cartProduct);
    }

    public Cart findById(Long id) {
        return cartRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found"));
    }

    public Cart getCartByCustomerId(Long customerId) {
        return cartRepository.findByCustomerId(customerId);
    }

    public void deleteCartById(Long idCart) {
        cartRepository.deleteById(idCart);
    }



}

