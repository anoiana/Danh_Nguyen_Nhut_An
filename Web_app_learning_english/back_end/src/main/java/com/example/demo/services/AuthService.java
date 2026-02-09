package com.example.demo.services;

import com.example.demo.entities.User;
import com.example.demo.entities.dto.AuthDTO;
import com.example.demo.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    /**
     * Registers a new user.
     * Checks if the username already exists.
     *
     * @param user The user entity to register.
     * @return A status message indicating success or failure.
     */
    public String register(User user) {
        if (userRepository.findByUsername(user.getUsername()).isPresent()) {
            return "Username already exists";
        }
        userRepository.save(user);
        return "Registration successful";
    }

    /**
     * Authenticates a user.
     * Checks username and password.
     *
     * @param loginRequest DTO containing username and password.
     * @return LoginResponse DTO if successful, null otherwise.
     */
    public AuthDTO.LoginResponse login(AuthDTO.LoginRequest loginRequest) {
        User user = userRepository.findByUsername(loginRequest.username())
                .orElse(null);
        if (user == null || !loginRequest.password().equals(user.getPassword())) {
            return null;
        }
        return new AuthDTO.LoginResponse("Login successful", user.getId(), user.getUsername());
    }
}
