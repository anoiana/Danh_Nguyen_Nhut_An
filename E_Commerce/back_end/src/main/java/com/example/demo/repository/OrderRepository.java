package com.example.demo.repository;

import com.example.demo.model.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {

    /**
     * Tìm tất cả các đơn hàng của một người dùng cụ thể,
     * sắp xếp theo ngày đặt hàng giảm dần (đơn hàng mới nhất lên đầu).
     * Phương thức này rất quan trọng cho chức năng "Xem lịch sử mua hàng"
     * trong trang quản lý khách hàng của admin.
     *
     * @param userId ID của người dùng (User) cần tìm đơn hàng.
     * @return một List các đơn hàng của người dùng đó.
     */
    List<Order> findByUserIdOrderByOrderDateDesc(Long userId);
    @Query("SELECT o FROM Order o LEFT JOIN FETCH o.orderItems WHERE o.id = :id")
    Optional<Order> findByIdWithItems(@Param("id") Long id);
    List<Order> findTop5ByOrderByOrderDateDesc(); // Thêm phương thức này để lấy đơn hàng gần đây

    // --- THÊM CÁC PHƯƠNG THỨC NÀY ---
    @Query("SELECT COALESCE(SUM(o.totalAmount), 0) FROM Order o WHERE o.status = :status AND o.orderDate BETWEEN :start AND :end")
    Double findTotalRevenueByStatusAndDateBetween(@Param("status") String status, @Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    Long countByOrderDateBetween(LocalDateTime start, LocalDateTime end);

    // Dùng để vẽ biểu đồ
    // SỬA LẠI PHƯƠNG THỨC NÀY TRONG OrderRepository.java
    @Query("SELECT FUNCTION('DATE', o.orderDate) as date, SUM(o.totalAmount) as total FROM Order o WHERE o.orderDate BETWEEN :start AND :end AND o.status = 'DELIVERED' GROUP BY FUNCTION('DATE', o.orderDate) ORDER BY FUNCTION('DATE', o.orderDate) ASC")
    List<Object[]> findDailyRevenueBetween(@Param("start") LocalDateTime start, @Param("end") LocalDateTime end);
    @Query("SELECT COALESCE(SUM(o.totalAmount), 0.0) FROM Order o WHERE o.user.id = :userId AND o.status = 'DELIVERED'")
    Double findTotalSpentByUserId(@Param("userId") Long userId);
}