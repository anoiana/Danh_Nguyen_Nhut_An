package com.example.demo.features.user.service;

import com.example.demo.features.user.dto.UserDto;
import com.example.demo.features.user.entity.User;
import com.example.demo.features.user.repository.UserRepository;
import com.example.demo.infra.exception.AuthException;
import com.example.demo.infra.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * Service managing user account operations and profile metadata.
 */
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder encoder;

    public Optional<User> findById(Long id) {
        return userRepository.findById(id);
    }

    public User findByIdOrThrow(Long id) {
        return findById(id).orElseThrow(
                () -> new ResourceNotFoundException("User not found with id: " + id));
    }

    public Optional<User> findByEmail(String email) {
        return userRepository.findByEmail(email);
    }

    @Transactional
    public void registerUser(UserDto signUpRequest) {
        if (userRepository.findByEmail(signUpRequest.getEmail()).isPresent()) {
            throw new AuthException("Error: Email is already in use!");
        }

        User user = new User();
        user.setName(signUpRequest.getName());
        user.setEmail(signUpRequest.getEmail());
        user.setPassword(encoder.encode(signUpRequest.getPassword()));
        user.setAge(signUpRequest.getAge());
        user.setGender(signUpRequest.getGender());
        user.setBio(signUpRequest.getBio());
        user.setAvatarUrl(signUpRequest.getAvatarUrl());
        user.setInterests(signUpRequest.getInterests());

        userRepository.save(user);
    }

    @Transactional
    public User registerGoogleUser(String email, String name, String pictureUrl) {
        return userRepository.findByEmail(email).orElseGet(() -> {
            User newUser = new User();
            newUser.setEmail(email);
            newUser.setName(name);
            newUser.setAvatarUrl(pictureUrl);
            newUser.setPassword(encoder.encode("GOOGLE_AUTH_USER_" + email));
            return userRepository.save(newUser);
        });
    }

    @Transactional
    public User save(User user) {
        return userRepository.save(user);
    }

    public List<User> findAll() {
        return userRepository.findAll();
    }
}
