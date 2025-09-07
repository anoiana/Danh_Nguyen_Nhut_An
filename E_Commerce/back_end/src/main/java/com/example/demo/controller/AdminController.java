package com.example.demo.controller;

import com.example.demo.dto.OrderListViewDTO;
import com.example.demo.model.Order;
import com.example.demo.repository.OrderRepository;
import com.example.demo.repository.ProductSizeRepository;
import com.example.demo.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    @Autowired private UserRepository userRepository;
    @Autowired private OrderRepository orderRepository;
    @Autowired private ProductSizeRepository productSizeRepository;

    private static final int LOW_STOCK_THRESHOLD = 10;

    @GetMapping("/dashboard/stats")
    public ResponseEntity<?> getDashboardStats() {
        // --- Tính toán thời gian ---
        LocalDate today = LocalDate.now();
        LocalDateTime startOfToday = today.atStartOfDay();
        LocalDateTime endOfToday = today.atTime(LocalTime.MAX);

        YearMonth currentMonth = YearMonth.now();
        LocalDateTime startOfMonth = currentMonth.atDay(1).atStartOfDay();
        LocalDateTime endOfMonth = currentMonth.atEndOfMonth().atTime(LocalTime.MAX);

        // --- Truy vấn dữ liệu ---
        Double monthlyRevenue = orderRepository.findTotalRevenueByStatusAndDateBetween("DELIVERED", startOfMonth, endOfMonth);
        Long newOrdersToday = orderRepository.countByOrderDateBetween(startOfToday, endOfToday);
        Long newCustomersMonth = userRepository.countByCreatedAtBetween(startOfMonth, endOfMonth); // Giả sử User có trường createdAt
        Long lowStockProducts = productSizeRepository.countByQuantityInStockLessThan(LOW_STOCK_THRESHOLD);
        List<Order> recentOrders = orderRepository.findTop5ByOrderByOrderDateDesc();

        // Chuyển đổi recentOrders sang DTO
        List<OrderListViewDTO> recentOrdersDTO = recentOrders.stream()
                .map(this::convertToOrderListViewDTO)
                .collect(Collectors.toList());

        // --- Dữ liệu cho biểu đồ (doanh thu mỗi ngày trong tháng) ---
        List<Object[]> dailyRevenueData = orderRepository.findDailyRevenueBetween(startOfMonth, endOfMonth);
        Map<String, Double> revenueChartData = new HashMap<>();
        dailyRevenueData.forEach(row -> {
            String date = row[0].toString();
            Double revenue = (Double) row[1];
            revenueChartData.put(date, revenue);
        });

        // --- Đóng gói và trả về ---
        Map<String, Object> dashboardData = new HashMap<>();
        dashboardData.put("monthlyRevenue", monthlyRevenue);
        dashboardData.put("newOrdersToday", newOrdersToday);
        dashboardData.put("newCustomersMonth", newCustomersMonth);
        dashboardData.put("lowStockProducts", lowStockProducts);
        dashboardData.put("recentOrders", recentOrdersDTO);
        dashboardData.put("revenueChartData", revenueChartData);

        return ResponseEntity.ok(dashboardData);
    }

    private OrderListViewDTO convertToOrderListViewDTO(Order order) {
        OrderListViewDTO dto = new OrderListViewDTO();
        dto.setId(order.getId());
        dto.setCustomerName(order.getCustomerName());
        dto.setOrderDate(order.getOrderDate());
        dto.setTotalAmount(order.getTotalAmount());
        dto.setStatus(order.getStatus());
        return dto;
    }
}