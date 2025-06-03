package com.springcommerce.springcommerce;

import com.springcommerce.springcommerce.entity.Customer;
import com.springcommerce.springcommerce.service.CustomerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private CustomerService customerService;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        // Tạo admin nếu chưa có
        if (customerService.findByEmail("admin@example.com") == null) {
            Customer admin = new Customer();
            admin.setName("Admin User");
            admin.setEmail("admin@example.com");
            admin.setPassword(passwordEncoder.encode("admin123")); // Mật khẩu mạnh hơn nhé!
            admin.setRoles("ADMIN,USER"); // Admin có thể có cả 2 roles
            // admin.addCart(...); // Admin cũng có thể có giỏ hàng nếu cần
            customerService.saveCustomer(admin);
            System.out.println("Admin user created: admin@example.com / admin123");
        }
    }
}