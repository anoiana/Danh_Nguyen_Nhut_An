package com.example.demo.repository;

import com.example.demo.model.Product;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {
    @Query("SELECT p FROM Product p LEFT JOIN FETCH p.variants v LEFT JOIN FETCH v.sizes WHERE p.id = :id")
    Optional<Product> findByIdWithDetails(@Param("id") Long id);

    @Override
    @Query("SELECT DISTINCT p FROM Product p LEFT JOIN FETCH p.reviews")
    List<Product> findAll();

    Page<Product> findByCategoryId(Long categoryId, Pageable pageable);

    @Query("SELECT p FROM Product p")
    Page<Product> findAllProducts(Pageable pageable);

    @Query("SELECT p FROM Product p JOIN p.promotions promo WHERE promo.isActive = true AND promo.startDate <= CURRENT_DATE AND promo.endDate >= CURRENT_DATE")
    Page<Product> findActivePromotionalProducts(Pageable pageable);

    Page<Product> findByCategoryIdAndIdNot(Long categoryId, Long productId, Pageable pageable);
}