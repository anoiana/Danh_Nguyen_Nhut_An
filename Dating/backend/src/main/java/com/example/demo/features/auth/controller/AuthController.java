package com.example.demo.features.auth.controller;

import com.example.demo.features.auth.dto.GoogleAuthRequest;
import com.example.demo.features.auth.dto.JwtResponse;
import com.example.demo.features.user.dto.UserDto;
import com.example.demo.features.user.entity.User;
import com.example.demo.features.user.service.UserService;
import com.example.demo.infra.exception.AuthException;
import com.example.demo.infra.security.JwtUtils;
import com.example.demo.infra.security.UserDetailsImpl;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Handles security-related endpoints, including traditional login/register
 * and Google OAuth2 social authentication.
 */
@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final UserService userService;
    private final JwtUtils jwtUtils;

    @Value("${demo.app.googleClientId}")
    private String googleClientId;

    /**
     * Entry point for Google Social Login.
     */
    @PostMapping("/google")
    public ResponseEntity<JwtResponse> googleLogin(@RequestBody GoogleAuthRequest googleAuthRequest) {
        try {
            GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(new NetHttpTransport(),
                    new GsonFactory())
                    .setAudience(Collections.singletonList(googleClientId))
                    .build();

            GoogleIdToken idToken = verifier.verify(googleAuthRequest.getIdToken());
            if (idToken == null) {
                throw new AuthException("Invalid Google ID token");
            }

            GoogleIdToken.Payload payload = idToken.getPayload();
            String email = payload.getEmail();
            String name = (String) payload.get("name");
            String pictureUrl = (String) payload.get("picture");

            User user = userService.registerGoogleUser(email, name, pictureUrl);

            UserDetailsImpl userDetails = UserDetailsImpl.build(user);
            UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                    userDetails, null, userDetails.getAuthorities());

            SecurityContextHolder.getContext().setAuthentication(authentication);
            String jwt = jwtUtils.generateJwtToken(authentication);

            return ResponseEntity.ok(buildJwtResponse(jwt, userDetails));

        } catch (GeneralSecurityException | IOException e) {
            throw new AuthException("Security error during Google login: " + e.getMessage());
        }
    }

    /**
     * Traditional Email/Password login.
     */
    @PostMapping("/login")
    public ResponseEntity<JwtResponse> authenticateUser(@Valid @RequestBody UserDto loginRequest) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(loginRequest.getEmail(), loginRequest.getPassword()));

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = jwtUtils.generateJwtToken(authentication);

        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
        return ResponseEntity.ok(buildJwtResponse(jwt, userDetails));
    }

    /**
     * Standard registration for new users.
     */
    @PostMapping("/register")
    public ResponseEntity<String> registerUser(@Valid @RequestBody UserDto signUpRequest) {
        userService.registerUser(signUpRequest);
        return ResponseEntity.ok("User registered successfully!");
    }

    private JwtResponse buildJwtResponse(String jwt, UserDetailsImpl userDetails) {
        List<String> roles = userDetails.getAuthorities().stream()
                .map(item -> item.getAuthority())
                .collect(Collectors.toList());

        return new JwtResponse(jwt,
                userDetails.getId(),
                userDetails.getEmail(),
                userDetails.getName(),
                userDetails.getAge(),
                userDetails.getGender(),
                userDetails.getBio(),
                userDetails.getAvatarUrl(),
                userDetails.getInterests(),
                userDetails.getPhotos(),
                roles);
    }
}
