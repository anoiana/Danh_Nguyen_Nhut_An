package com.example.demo.controller;

import com.example.demo.dto.CustomerDetailViewDTO;
import com.example.demo.dto.CustomerListDTO;
import com.example.demo.dto.AdminCreateCustomerRequestDTO; // <-- IMPORT MỚI
import com.example.demo.dto.AdminUpdateCustomerRequestDTO; // <-- IMPORT MỚI
import com.example.demo.model.ERole;
import com.example.demo.model.Role;
import com.example.demo.model.User;
import com.example.demo.repository.OrderRepository;
import com.example.demo.repository.RoleRepository;
import com.example.demo.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/customers")
@PreAuthorize("hasRole('ADMIN')")
public class CustomerAdminController {

    @Autowired private UserRepository userRepository;
    @Autowired private OrderRepository orderRepository;
    @Autowired private RoleRepository roleRepository;
    @Autowired private PasswordEncoder passwordEncoder;

    // API THÊM KHÁCH HÀNG MỚI (ĐÃ SỬA)
    @PostMapping
    public ResponseEntity<?> createCustomer(@RequestBody AdminCreateCustomerRequestDTO requestDTO) { // <-- SỬA Ở ĐÂY
        if (userRepository.existsByUsername(requestDTO.getUsername())) {
            return ResponseEntity.badRequest().body(new CustomerDetailViewDTO.MessageResponse("Error: Username is already taken!"));
        }
        if (userRepository.existsByEmail(requestDTO.getEmail())) {
            return ResponseEntity.badRequest().body(new CustomerDetailViewDTO.MessageResponse("Error: Email is already in use!"));
        }

        // Tạo đối tượng User từ DTO
        User newUser = new User();
        newUser.setUsername(requestDTO.getUsername());
        newUser.setEmail(requestDTO.getEmail());
        newUser.setPassword(passwordEncoder.encode(requestDTO.getPassword())); // Mã hóa mật khẩu
        newUser.setPhoneNumber(requestDTO.getPhoneNumber());
        newUser.setAddress(requestDTO.getAddress());
        newUser.setProvince(requestDTO.getProvince());
        newUser.setDistrict(requestDTO.getDistrict());
        newUser.setWard(requestDTO.getWard());

        // Gán vai trò mặc định là CUSTOMER
        Set<Role> roles = new HashSet<>();
        Role customerRole = roleRepository.findByName(ERole.ROLE_CUSTOMER)
                .orElseThrow(() -> new RuntimeException("Error: Role CUSTOMER is not found."));
        roles.add(customerRole);
        newUser.setRoles(roles);

        // Kích hoạt tài khoản luôn vì do admin tạo
        newUser.setEnabled(true);

        User savedUser = userRepository.save(newUser);

        savedUser.setPassword(null); // Không trả về mật khẩu
        return ResponseEntity.ok(savedUser);
    }

    // API LẤY CHI TIẾT KHÁCH HÀNG (Giữ nguyên, không có lỗi)
    @GetMapping("/{id}")
    @Transactional(readOnly = true)
    public ResponseEntity<?> getCustomerDetails(@PathVariable Long id) {
        return userRepository.findById(id)
                .map(user -> {
                    user.setPassword(null);
                    return ResponseEntity.ok(user);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    // API CẬP NHẬT KHÁCH HÀNG (ĐÃ SỬA)
    @PutMapping("/{id}")
    @Transactional
    public ResponseEntity<?> updateCustomer(@PathVariable Long id, @RequestBody AdminUpdateCustomerRequestDTO requestDTO) { // <-- SỬA Ở ĐÂY
        return userRepository.findById(id)
                .map(user -> {
                    // Cập nhật thông tin từ DTO
                    user.setUsername(requestDTO.getUsername());
                    user.setEmail(requestDTO.getEmail());
                    user.setPhoneNumber(requestDTO.getPhoneNumber());
                    user.setAddress(requestDTO.getAddress());
                    user.setProvince(requestDTO.getProvince());
                    user.setDistrict(requestDTO.getDistrict());
                    user.setWard(requestDTO.getWard());
                    user.setEnabled(requestDTO.isEnabled());
                    
                    userRepository.save(user);
                    return ResponseEntity.ok(new CustomerDetailViewDTO.MessageResponse("Customer updated successfully!"));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    // API XÓA KHÁCH HÀNG (Giữ nguyên, không có lỗi)
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteCustomer(@PathVariable Long id) {
        if (!userRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        userRepository.deleteById(id);
        return ResponseEntity.ok(new CustomerDetailViewDTO.MessageResponse("Customer deleted successfully!"));
    }

    // API LẤY DANH SÁCH KHÁCH HÀNG (Giữ nguyên, không có lỗi)
    @GetMapping
    @Transactional(readOnly = true)
    public ResponseEntity<List<CustomerListDTO>> getAllCustomers() {
        List<User> customers = userRepository.findAll().stream()
                .filter(user -> user.getRoles().stream()
                        .anyMatch(role -> role.getName() == ERole.ROLE_CUSTOMER))
                .toList();
        List<CustomerListDTO> dtos = customers.stream()
                .map(this::convertToCustomerListDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    private CustomerListDTO convertToCustomerListDTO(User user) {
        CustomerListDTO dto = new CustomerListDTO();
        dto.setId(user.getId());
        dto.setUsername(user.getUsername());
        dto.setEmail(user.getEmail());
        dto.setJoinDate(user.getCreatedAt());
        dto.setEnabled(user.isEnabled());
        Double totalSpent = orderRepository.findTotalSpentByUserId(user.getId());
        dto.setTotalSpent(totalSpent);
        return dto;
    }
}