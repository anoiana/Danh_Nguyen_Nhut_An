package com.springcommerce.springcommerce.config;

// import com.springcommerce.springcommerce.entity.Customer;
// import com.springcommerce.springcommerce.service.CustomerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.HeadersConfigurer; // Thêm import này
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.util.matcher.AntPathRequestMatcher;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Autowired
    private UserDetailsService userDetailsService;

    // @Autowired
    // private CustomerService customerService;

    @Bean
    public static PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public DaoAuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .headers(headers -> headers // Cấu hình headers để kiểm soát cache
                        .cacheControl(HeadersConfigurer.CacheControlConfig::disable) // Tương đương .cacheControl(cache -> cache.disable())
                        .frameOptions(HeadersConfigurer.FrameOptionsConfig::sameOrigin) // Bảo vệ chống clickjacking
                )
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(
                                "/css/**",
                                "/js/**",
                                "/images/**",      // Ảnh trong static/images
                                "/uploads/**",     // <<<< CHO PHÉP TRUY CẬP ẢNH UPLOADED
                                "/webjars/**",
                                "/assets_cus/**",
                                "/assets_ad/**"
                        ).permitAll()
                        .requestMatchers(
                                "/",
                                "/customer",
                                "/customer/fashion",
                                "/customer/electronic",
                                "/customer/jewellery",
                                "/customer/detailProduct",
                                "/customer/search"
                        ).permitAll()
                        .requestMatchers(
                                "/customer/login",
                                "/customer/register"
                        ).permitAll()
                        .requestMatchers("/customer/cart/**").hasRole("USER")
                        .requestMatchers("/admin/**").hasRole("ADMIN")
                        .anyRequest().authenticated()
                )
                .formLogin(form -> form
                        .loginPage("/customer/login")
                        .loginProcessingUrl("/customer/loginCustomer")
                        .successHandler((request, response, authentication) -> {
                            boolean isAdmin = authentication.getAuthorities().stream()
                                    .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
                            boolean isUser = authentication.getAuthorities().stream()
                                    .anyMatch(a -> a.getAuthority().equals("ROLE_USER"));

                            if (isAdmin) {
                                response.sendRedirect("/admin");
                            } else if (isUser) {
                                response.sendRedirect("/customer");
                            } else {
                                response.sendRedirect("/");
                            }
                        })
                        .failureUrl("/customer/login?error=true")
                        .permitAll()
                )
                .logout(logout -> logout
                        .logoutRequestMatcher(new AntPathRequestMatcher("/logout", "GET"))
                        .logoutSuccessUrl("/customer/login?logout=true")
                        .invalidateHttpSession(true)
                        .deleteCookies("JSESSIONID") // Đảm bảo tên cookie session là JSESSIONID (mặc định)
                        .clearAuthentication(true)
                        .permitAll()
                );
        return http.build();
    }
}