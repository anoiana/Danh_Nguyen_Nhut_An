package com.springcommerce.springcommerce.service;

import com.springcommerce.springcommerce.Repository.CustomerRepository;
import com.springcommerce.springcommerce.entity.Cart;
import com.springcommerce.springcommerce.entity.Customer;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class CustomerService {

    @Autowired
    private CustomerRepository customerRepository;

    public void saveCustomer(Customer customer) {
        // Mã hóa mật khẩu trước khi lưu
        customerRepository.save(customer);
    }

    public Customer findByEmail(String email) {
        return customerRepository.findByEmail(email);
    }

    public Customer findById(Long id) {
        return customerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Customer not found"));
    }
}
