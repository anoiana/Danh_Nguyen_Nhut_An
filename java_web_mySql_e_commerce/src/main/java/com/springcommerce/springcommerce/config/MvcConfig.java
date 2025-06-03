package com.springcommerce.springcommerce.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class MvcConfig implements WebMvcConfigurer {

    // Lấy đường dẫn tuyệt đối của thư mục upload từ application.properties
    // Ví dụ: file.upload-dir-absolute=E:/Image
    @Value("${file.upload-dir-absolute}")
    private String uploadDirAbsolute;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // Phục vụ các file từ thư mục /uploads/
        // Ánh xạ đường dẫn URL /uploads/** tới thư mục vật lý trên server
        // Quan trọng: "file:" + uploadDirAbsolute + (uploadDirAbsolute.endsWith("/") ? "" : "/")
        // Đảm bảo có dấu "/" ở cuối đường dẫn thư mục vật lý
        String resourceLocation = "file:" + uploadDirAbsolute + (uploadDirAbsolute.endsWith("/") || uploadDirAbsolute.endsWith("\\") ? "" : "/");
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations(resourceLocation);

        // Giữ lại hoặc thêm các cấu hình resource handler khác nếu cần
        // Ví dụ, nếu bạn vẫn muốn phục vụ từ classpath/static cho các assets khác:
        // registry.addResourceHandler("/static/**").addResourceLocations("classpath:/static/");
        // Tuy nhiên, SecurityConfig của bạn đã permitAll /css, /js, /images, /assets_cus, /assets_ad
        // nên các file trong static/css, static/js, static/images sẽ được phục vụ tự động
        // nếu chúng khớp với các pattern đó.
    }
}