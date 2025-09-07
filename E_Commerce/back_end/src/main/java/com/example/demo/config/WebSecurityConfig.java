package com.example.demo.config;

import com.example.demo.security.jwt.AuthEntryPointJwt;
import com.example.demo.security.jwt.AuthTokenFilter;
import com.example.demo.security.services.UserDetailsServiceImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;


@Configuration
@EnableMethodSecurity
public class WebSecurityConfig {

    @Autowired
    private UserDetailsServiceImpl userDetailsService;

    @Autowired
    private AuthEntryPointJwt unauthorizedHandler;

    @Autowired
    private AuthTokenFilter authTokenFilter;

    @Bean
    public DaoAuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authConfig) throws Exception {
        return authConfig.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                // Sử dụng cấu hình CORS được định nghĩa trong bean corsConfigurationSource
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))

                // Tắt CSRF vì chúng ta sử dụng JWT (stateless)
                .csrf(csrf -> csrf.disable())

                // Cấu hình xử lý ngoại lệ, đặc biệt cho lỗi 401
                .exceptionHandling(exception -> exception.authenticationEntryPoint(unauthorizedHandler))

                // Cấu hình quản lý phiên làm việc là STATELESS
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                // Phân quyền cho các request HTTP
                .authorizeHttpRequests(auth ->
                        auth
                                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                                .requestMatchers("/api/auth/**").permitAll()
                                .requestMatchers("/api/home/**").permitAll()
                                .requestMatchers("/api/products-page/**").permitAll()
                                .requestMatchers("/api/categories/**").permitAll() // Cho phép /api/categories và /api/categories/{id}/products
                                .requestMatchers(HttpMethod.GET, "/api/products/**").permitAll() // Cho phép XEM tất cả sản phẩm và review
                                .requestMatchers("/api/coupons/validate/**").permitAll()

                                // =========================================================
                                // 2. CÁC ENDPOINT YÊU CẦU ĐĂNG NHẬP (ROLE BẤT KỲ)
                                // =========================================================
                                .requestMatchers("/api/user/**").authenticated()
                                .requestMatchers("/api/cart/**").authenticated()
                                .requestMatchers("/api/orders").authenticated() // Đặt hàng
                                .requestMatchers("/api/user/orders/**").authenticated() // Đơn hàng của user

                                // SỬA LẠI CÁC QUY TẮC REVIEW Ở ĐÂY
                                .requestMatchers(HttpMethod.POST, "/api/products/{productId}/reviews").authenticated() // Gửi review
                                .requestMatchers(HttpMethod.GET, "/api/products/{productId}/reviews/check").authenticated() // Check quyền
                                .requestMatchers("/api/reviews/**").authenticated() // Sửa/Xóa review theo reviewId

                                // =========================================================
                                // 3. CÁC ENDPOINT DÀNH RIÊNG CHO ADMIN
                                // =========================================================
                                .requestMatchers("/api/admin/**").hasRole("ADMIN")

                                // =========================================================
                                // 4. MẶC ĐỊNH: MỌI REQUEST CÒN LẠI CẦN ĐĂNG NHẬP
                                // =========================================================
                                .anyRequest().authenticated()
                );

        // Thêm provider xác thực
        http.authenticationProvider(authenticationProvider());

        // Thêm bộ lọc JWT trước bộ lọc UsernamePasswordAuthenticationFilter
        http.addFilterBefore(authTokenFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();

        // Chỉ định các nguồn gốc (frontend) được phép.
        // Cần phải rất cụ thể, không nên dùng "*" trong môi trường production.
        configuration.setAllowedOrigins(Arrays.asList(
                "http://localhost:3000", // Ví dụ cho React
                "http://localhost:4200", // Ví dụ cho Angular
                "http://localhost:8081", // Ví dụ cho Vue
                "http://127.0.0.1:5500"  // Ví dụ cho Live Server của VSCode
        ));

        // Các phương thức HTTP được phép
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));

        // Các header được phép gửi trong request
        configuration.setAllowedHeaders(Arrays.asList("Authorization", "Content-Type", "Accept"));

        // Cho phép trình duyệt gửi thông tin xác thực (như cookie, authorization headers)
        configuration.setAllowCredentials(true);

        // Thời gian cache của pre-flight request (tính bằng giây)
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        // Áp dụng cấu hình CORS này cho tất cả các đường dẫn trong ứng dụng
        source.registerCorsConfiguration("/**", configuration);

        return source;
    }
}