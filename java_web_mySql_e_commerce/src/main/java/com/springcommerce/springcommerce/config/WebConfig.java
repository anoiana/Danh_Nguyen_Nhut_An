package com.springcommerce.springcommerce.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // Đảm bảo đường dẫn URL và thư mục lưu ảnh là chính xác
        registry.addResourceHandler("/uploads/**")  // Sử dụng "/uploads/" thay vì "/Image/"
                .addResourceLocations("file:/E:/Image/"); // Đảm bảo thêm 'file:' vào đầu đường dẫn tuyệt đối
    }
}

