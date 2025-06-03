package com.springcommerce.springcommerce.Repository;

import com.springcommerce.springcommerce.entity.CartProduct;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CartProductRepository extends JpaRepository<CartProduct, Long> {
    // Các phương thức tùy chỉnh sẽ được thêm sau
}