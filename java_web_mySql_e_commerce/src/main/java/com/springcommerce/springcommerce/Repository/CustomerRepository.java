package com.springcommerce.springcommerce.Repository;

import com.springcommerce.springcommerce.entity.Customer;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CustomerRepository extends JpaRepository<Customer, Long> {
    // Các phương thức tùy chỉnh sẽ được thêm sau
    Customer findByEmail(String email);
}