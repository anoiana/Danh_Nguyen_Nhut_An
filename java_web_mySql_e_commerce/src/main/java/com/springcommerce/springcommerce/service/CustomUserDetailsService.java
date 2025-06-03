package com.springcommerce.springcommerce.service;

import com.springcommerce.springcommerce.entity.Customer;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.Collection;
import java.util.stream.Collectors;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    @Autowired
    private CustomerService customerService; // Service để tìm Customer

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        Customer customer = customerService.findByEmail(email);
        if (customer == null) {
            throw new UsernameNotFoundException("User not found with email: " + email);
        }

        // Giả sử bạn có một trường 'roles' trong Customer, ví dụ: "USER,ADMIN" hoặc chỉ "USER"
        // Nếu không có, bạn cần thêm trường này vào Entity Customer
        // Hoặc bạn có thể mặc định tất cả customer là "ROLE_USER" và admin có role riêng
        Collection<? extends GrantedAuthority> authorities =
                Arrays.stream(customer.getRoles().split(",")) // Cần thêm trường getRoles() vào Customer Entity
                        .map(role -> new SimpleGrantedAuthority("ROLE_" + role.trim().toUpperCase())) // Quan trọng: Prefix "ROLE_"
                        .collect(Collectors.toList());

        return new org.springframework.security.core.userdetails.User(
                customer.getEmail(),
                customer.getPassword(), // Mật khẩu đã được hash
                authorities
        );
    }
}
