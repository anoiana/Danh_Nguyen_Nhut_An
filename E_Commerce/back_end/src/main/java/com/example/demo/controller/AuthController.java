package com.example.demo.controller;


import com.example.demo.dto.AdminUpdateCustomerRequestDTO;
import com.example.demo.dto.CustomerDetailViewDTO;
import com.example.demo.model.*;
import com.example.demo.repository.*;
import com.example.demo.security.jwt.JwtUtils;
import com.example.demo.security.services.UserDetailsImpl;
import com.example.demo.service.EmailService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired AuthenticationManager authenticationManager;
    @Autowired UserRepository userRepository;
    @Autowired RoleRepository roleRepository;
    @Autowired VerificationTokenRepository verificationTokenRepository;
    @Autowired PasswordResetTokenRepository passwordResetTokenRepository;
    @Autowired PasswordEncoder encoder;
    @Autowired JwtUtils jwtUtils;
    @Autowired EmailService emailService;

    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@Valid @RequestBody AdminUpdateCustomerRequestDTO.RegisterRequest registerRequest) {
        if (userRepository.existsByUsername(registerRequest.getUsername())) {
            return ResponseEntity.badRequest().body(new CustomerDetailViewDTO.MessageResponse("Error: Username is already taken!"));
        }
        if (userRepository.existsByEmail(registerRequest.getEmail())) {
            return ResponseEntity.badRequest().body(new CustomerDetailViewDTO.MessageResponse("Error: Email is already in use!"));
        }

        // Tạo user mới, chưa kích hoạt
        User user = new User(registerRequest.getUsername(), registerRequest.getEmail(), encoder.encode(registerRequest.getPassword()));

        Set<Role> roles = new HashSet<>();
        Role customerRole = roleRepository.findByName(ERole.ROLE_CUSTOMER)
                .orElseThrow(() -> new RuntimeException("Error: Role is not found."));
        roles.add(customerRole);
        user.setRoles(roles);

        userRepository.save(user);

        // Tạo token xác thực và gửi email
        String token = UUID.randomUUID().toString();
        VerificationToken verificationToken = new VerificationToken(token, user, LocalDateTime.now().plusHours(24));
        verificationTokenRepository.save(verificationToken);

        String confirmationUrl = "http://localhost:8080/api/auth/confirm?token=" + token; // Thay đổi URL nếu cần
        String message = "Cảm ơn bạn đã đăng ký. Vui lòng click vào link sau để kích hoạt tài khoản của bạn:\n" + confirmationUrl;
        emailService.sendEmail(user.getEmail(), "Xác thực tài khoản", message);

        return ResponseEntity.ok(new CustomerDetailViewDTO.MessageResponse("User registered successfully! Please check your email to verify your account."));
    }

    @GetMapping("/confirm")
    public ResponseEntity<?> confirmRegistration(@RequestParam("token") String token) {
        VerificationToken verificationToken = verificationTokenRepository.findByToken(token);
        if (verificationToken == null) {
            return ResponseEntity.badRequest().body(new CustomerDetailViewDTO.MessageResponse("Error: Invalid verification token!"));
        }
        if (verificationToken.getExpiryDate().isBefore(LocalDateTime.now())) {
            return ResponseEntity.badRequest().body(new CustomerDetailViewDTO.MessageResponse("Error: Expired verification token!"));
        }

        User user = verificationToken.getUser();
        user.setEnabled(true);
        userRepository.save(user);
        verificationTokenRepository.delete(verificationToken); // Xóa token sau khi đã sử dụng

        return ResponseEntity.ok(new CustomerDetailViewDTO.MessageResponse("Account activated successfully!"));
    }

    @PostMapping("/login")
    public ResponseEntity<?> authenticateUser(@Valid @RequestBody CustomerDetailViewDTO.LoginRequest loginRequest) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(loginRequest.getEmail(), loginRequest.getPassword()));

        SecurityContextHolder.getContext().setAuthentication(authentication);
        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();

        if (!userDetails.isEnabled()) {
            return ResponseEntity.status(403).body(new CustomerDetailViewDTO.MessageResponse("Error: Account is not activated!"));
        }

        String jwt = jwtUtils.generateJwtToken(userDetails);

        List<String> roles = userDetails.getAuthorities().stream()
                .map(item -> item.getAuthority())
                .collect(Collectors.toList());

        return ResponseEntity.ok(new CustomerDetailViewDTO.JwtResponse(jwt,
                userDetails.getId(),
                userDetails.getUsername(),
                userDetails.getEmail(),
                roles));
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<?> forgotPassword(@Valid @RequestBody CustomerDetailViewDTO.ForgotPasswordRequest forgotPasswordRequest) {
        User user = userRepository.findByEmail(forgotPasswordRequest.getEmail())
                .orElse(null);

        if (user != null) {
            String token = UUID.randomUUID().toString();
            PasswordResetToken resetToken = new PasswordResetToken(token, user, LocalDateTime.now().plusMinutes(30)); // Token hết hạn sau 30 phút
            passwordResetTokenRepository.save(resetToken);

            String resetUrl = "http://localhost:3000/reset-password?token=" + token; // Đây là URL của frontend
            String message = "Bạn đã yêu cầu đặt lại mật khẩu. Vui lòng click vào link sau để tiếp tục:\n" + resetUrl;
            emailService.sendEmail(user.getEmail(), "Yêu cầu đặt lại mật khẩu", message);
        }
        // Luôn trả về thành công để tránh kẻ tấn công biết được email nào tồn tại trong hệ thống
        return ResponseEntity.ok(new CustomerDetailViewDTO.MessageResponse("If your email is registered, you will receive a password reset link."));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<?> resetPassword(@Valid @RequestBody AdminUpdateCustomerRequestDTO.ResetPasswordRequest resetPasswordRequest) {
        PasswordResetToken resetToken = passwordResetTokenRepository.findByToken(resetPasswordRequest.getToken());

        if (resetToken == null) {
            return ResponseEntity.badRequest().body(new CustomerDetailViewDTO.MessageResponse("Error: Invalid reset token!"));
        }
        if (resetToken.getExpiryDate().isBefore(LocalDateTime.now())) {
            return ResponseEntity.badRequest().body(new CustomerDetailViewDTO.MessageResponse("Error: Expired reset token!"));
        }

        User user = resetToken.getUser();
        user.setPassword(encoder.encode(resetPasswordRequest.getNewPassword()));
        userRepository.save(user);
        passwordResetTokenRepository.delete(resetToken);

        return ResponseEntity.ok(new CustomerDetailViewDTO.MessageResponse("Password has been reset successfully!"));
    }
}