package com.springcommerce.springcommerce.Repository;

import com.springcommerce.springcommerce.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ProductRepository extends JpaRepository<Product, Long> {

    // Tìm kiếm sản phẩm theo danh mục
    List<Product> findByCategory(String category);

    // Tìm kiếm sản phẩm theo tên (không phân biệt chữ hoa/chữ thường)
    List<Product> findByProductNameContainingIgnoreCase(String productName);

    // Tìm kiếm sản phẩm theo giá chính xác
    List<Product> findByPrice(Double price);
}
