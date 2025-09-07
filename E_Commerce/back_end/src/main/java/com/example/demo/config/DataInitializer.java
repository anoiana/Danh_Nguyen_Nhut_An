package com.example.demo.config; // Hoặc package bạn muốn

import com.example.demo.model.ERole;
import com.example.demo.model.Role;
import com.example.demo.repository.RoleRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private RoleRepository roleRepository;

    @Override
    public void run(String... args) throws Exception {
        System.out.println("Initializing roles...");

        // Kiểm tra và thêm ROLE_CUSTOMER nếu chưa có
        if (roleRepository.findByName(ERole.ROLE_CUSTOMER).isEmpty()) {
            Role customerRole = new Role();
            customerRole.setName(ERole.ROLE_CUSTOMER);
            roleRepository.save(customerRole);
            System.out.println("ROLE_CUSTOMER has been added to the database.");
        }

        // Kiểm tra và thêm ROLE_ADMIN nếu chưa có
        if (roleRepository.findByName(ERole.ROLE_ADMIN).isEmpty()) {
            Role adminRole = new Role();
            adminRole.setName(ERole.ROLE_ADMIN);
            roleRepository.save(adminRole);
            System.out.println("ROLE_ADMIN has been added to the database.");
        }

        System.out.println("Roles initialization finished.");
    }
}