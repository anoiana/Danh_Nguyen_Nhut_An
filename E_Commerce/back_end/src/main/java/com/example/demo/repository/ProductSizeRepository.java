package com.example.demo.repository;

import com.example.demo.model.ProductSize;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProductSizeRepository extends JpaRepository<ProductSize, Long> {
    Long countByQuantityInStockLessThan(int threshold);
}