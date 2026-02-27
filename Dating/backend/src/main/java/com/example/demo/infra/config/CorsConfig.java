package com.example.demo.infra.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

import java.util.Collections;

@Configuration
public class CorsConfig {

    @Bean
    public CorsFilter corsFilter() {
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        CorsConfiguration config = new CorsConfiguration();

        // Cho phép gửi credentials (JWT, Cookies)
        config.setAllowCredentials(true);

        // Cho phép tất cả các Origin (Dùng Pattern để tương thích với link Vercel)
        config.setAllowedOriginPatterns(Collections.singletonList("*"));

        // Cho phép tất cả các Header
        config.addAllowedHeader("*");

        // Cho phép tất cả các Method
        config.addAllowedMethod("*");

        // Thời gian cache cấu hình CORS (1 tiếng)
        config.setMaxAge(3600L);

        source.registerCorsConfiguration("/**", config);
        return new CorsFilter(source);
    }
}
