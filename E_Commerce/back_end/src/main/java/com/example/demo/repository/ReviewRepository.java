package com.example.demo.repository;

import com.example.demo.model.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ReviewRepository extends JpaRepository<Review, Long> {

    /**
     * Tìm tất cả đánh giá cho một sản phẩm cụ thể, sắp xếp theo ngày mới nhất.
     */
    List<Review> findByProductIdOrderByReviewDateDesc(Long productId);

    /**
     * Kiểm tra xem một người dùng đã đánh giá một sản phẩm cụ thể hay chưa.
     * Rất hiệu quả cho việc kiểm tra quyền đánh giá.
     */
    boolean existsByUserIdAndProductId(Long userId, Long productId);
}