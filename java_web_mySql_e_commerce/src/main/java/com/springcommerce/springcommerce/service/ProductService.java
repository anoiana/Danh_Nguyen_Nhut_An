package com.springcommerce.springcommerce.service;

import com.springcommerce.springcommerce.Repository.ProductRepository;
import com.springcommerce.springcommerce.entity.Product;
import com.springcommerce.springcommerce.enums.Category;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils; // Thêm import này
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList; // Thêm import này
import java.util.List;
import java.util.Optional;
// import java.util.Base64; // Không thấy sử dụng Base64 trong code hiện tại

@Service
public class ProductService {

    @Autowired
    private ProductRepository productRepository;

    // Thư mục lưu trữ ảnh (nên cấu hình từ application.properties)
    private final String UPLOAD_DIR = "E:/Image/"; // Thư mục lưu ảnh ngoài ứng dụng Spring Boot
    private final String IMAGE_ACCESS_PATH_PREFIX = "/uploads/"; // Tiền tố đường dẫn truy cập ảnh

    public void addProduct(Product product, MultipartFile file) throws IOException {
        if (file != null && !file.isEmpty()) {
            String fileName = saveFileAndGetRelativePath(file);
            product.setLinkImg(fileName); // Lưu đường dẫn tương đối (URL)
        } else {
            // Có thể gán ảnh mặc định nếu không có file upload
            // product.setLinkImg("/images/default-product-image.jpg");
        }
        productRepository.save(product);
    }

    public List<Product> getAllProducts() {
        List<Product> products = productRepository.findAll();
        products.forEach(product -> {
            if (!StringUtils.hasText(product.getLinkImg())) { // Sử dụng StringUtils.hasText để kiểm tra null, empty và chỉ whitespace
                product.setLinkImg("/images/default-product-image.jpg");
            }
        });
        return products;
    }

    public void deleteProduct(Long productId) {
        // Cân nhắc xóa file ảnh liên quan khi xóa sản phẩm
        // Product product = findById(productId);
        // if (product != null && StringUtils.hasText(product.getLinkImg())) {
        //     deleteImageFile(product.getLinkImg());
        // }
        productRepository.deleteById(productId);
    }

    public Product findById(Long id) {
        return productRepository.findById(id)
                .map(product -> { // Xử lý ảnh mặc định nếu cần khi lấy chi tiết
                    if (!StringUtils.hasText(product.getLinkImg())) {
                        product.setLinkImg("/images/default-product-image.jpg");
                    }
                    return product;
                })
                .orElseThrow(() -> new RuntimeException("Product not found with ID: " + id));
    }

    public void updateProduct(Product productDetails, MultipartFile file) throws IOException {
        Product existingProduct = productRepository.findById(productDetails.getProductId())
                .orElseThrow(() -> new IllegalArgumentException("Product not found with ID: " + productDetails.getProductId()));

        existingProduct.setProductName(productDetails.getProductName());
        existingProduct.setDescription(productDetails.getDescription());
        existingProduct.setCategory(productDetails.getCategory());
        existingProduct.setPrice(productDetails.getPrice());
        existingProduct.setStock(productDetails.getStock());

        if (file != null && !file.isEmpty()) {
            // Cân nhắc xóa file ảnh cũ trước khi lưu file mới
            // if (StringUtils.hasText(existingProduct.getLinkImg())) {
            //     deleteImageFile(existingProduct.getLinkImg());
            // }
            String newFileName = saveFileAndGetRelativePath(file);
            existingProduct.setLinkImg(newFileName);
        }
        // Nếu không có file mới và muốn giữ ảnh cũ, không cần làm gì thêm với linkImg

        productRepository.save(existingProduct);
    }

    private String saveFileAndGetRelativePath(MultipartFile file) throws IOException {
        // Tạo tên file duy nhất để tránh trùng lặp
        String originalFileName = StringUtils.cleanPath(file.getOriginalFilename()); // Làm sạch tên file
        String extension = "";
        int i = originalFileName.lastIndexOf('.');
        if (i > 0) {
            extension = originalFileName.substring(i);
        }
        String fileNameWithoutExtension = originalFileName.substring(0, i > 0 ? i : originalFileName.length());

        String uniqueFileName = fileNameWithoutExtension + "_" + System.currentTimeMillis() + extension;

        Path uploadPath = Paths.get(UPLOAD_DIR);
        if (!Files.exists(uploadPath)) {
            Files.createDirectories(uploadPath);
        }

        Path filePath = uploadPath.resolve(uniqueFileName);
        Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

        return IMAGE_ACCESS_PATH_PREFIX + uniqueFileName; // Trả về đường dẫn tương đối để lưu vào DB
    }

    // Helper method để xóa file (nếu cần)
    private void deleteImageFile(String relativeImagePath) {
        if (relativeImagePath == null || !relativeImagePath.startsWith(IMAGE_ACCESS_PATH_PREFIX)) {
            return;
        }
        try {
            String fileName = relativeImagePath.substring(IMAGE_ACCESS_PATH_PREFIX.length());
            Path filePath = Paths.get(UPLOAD_DIR).resolve(fileName);
            Files.deleteIfExists(filePath);
        } catch (IOException e) {
            System.err.println("Error deleting image file: " + relativeImagePath + " - " + e.getMessage());
            // Log lỗi, không nên để ứng dụng chết vì không xóa được file
        }
    }


    public List<Product> getProductsByCategoryName(String categoryName) {
        String categoryId = Category.getIdByName(categoryName);
        if (categoryId != null) {
            List<Product> products = productRepository.findByCategory(categoryId);
            products.forEach(product -> { // Gán ảnh mặc định nếu thiếu
                if (!StringUtils.hasText(product.getLinkImg())) {
                    product.setLinkImg("/images/default-product-image.jpg");
                }
            });
            return products;
        }
        return List.of();
    }

    public List<Product> searchProductsByName(String productName) {
        if (!StringUtils.hasText(productName)) {
            return new ArrayList<>(); // Trả về rỗng nếu keyword không hợp lệ
        }
        List<Product> products = productRepository.findByProductNameContainingIgnoreCase(productName);
        products.forEach(product -> {
            if (!StringUtils.hasText(product.getLinkImg())) {
                product.setLinkImg("/images/default-product-image.jpg");
            }
        });
        return products;
    }

    public List<Product> searchByPrice(Double price) {
        if (price == null || price < 0) {
            return new ArrayList<>(); // Trả về rỗng nếu giá không hợp lệ
        }
        List<Product> products = productRepository.findByPrice(price);
        products.forEach(product -> {
            if (!StringUtils.hasText(product.getLinkImg())) {
                product.setLinkImg("/images/default-product-image.jpg");
            }
        });
        return products;
    }

    public void deleteProductsByIds(List<Long> productIds) {
        if (productIds != null && !productIds.isEmpty()) {
            // Cân nhắc xóa file ảnh của các sản phẩm này
            // List<Product> productsToDelete = productRepository.findAllById(productIds);
            // productsToDelete.forEach(p -> {
            //     if (StringUtils.hasText(p.getLinkImg())) {
            //         deleteImageFile(p.getLinkImg());
            //     }
            // });
            productRepository.deleteAllByIdInBatch(productIds); // Hiệu quả hơn cho việc xóa nhiều bản ghi
        }
    }

    /**
     * Tìm kiếm sản phẩm theo tên hoặc theo category (sử dụng categoryId từ Enum).
     *
     * @param keyword Từ khóa tìm kiếm.
     * @return Danh sách các sản phẩm phù hợp.
     */
    public List<Product> searchProductsByNameOrCategory(String keyword) {
        if (!StringUtils.hasText(keyword)) {
            return new ArrayList<>(); // Trả về danh sách rỗng nếu từ khóa trống
        }

        // Tìm kiếm theo tên sản phẩm
        List<Product> productsByName = productRepository.findByProductNameContainingIgnoreCase(keyword);

        // Cố gắng tìm kiếm theo category nếu keyword có thể là tên category
        List<Product> productsByCategory = new ArrayList<>();
        String categoryId = Category.getIdByName(keyword); // Giả sử getIdByName trả về null nếu không tìm thấy
        if (categoryId != null) {
            productsByCategory = productRepository.findByCategory(categoryId);
        }

        // Kết hợp kết quả và loại bỏ trùng lặp (nếu có)
        // Một cách đơn giản là gộp và dùng Set, hoặc kiểm tra trước khi thêm
        List<Product> combinedResults = new ArrayList<>(productsByName);
        for (Product pCat : productsByCategory) {
            boolean found = false;
            for (Product pName : productsByName) {
                if (pName.getProductId().equals(pCat.getProductId())) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                combinedResults.add(pCat);
            }
        }

        combinedResults.forEach(product -> {
            if (!StringUtils.hasText(product.getLinkImg())) {
                product.setLinkImg("/images/default-product-image.jpg");
            }
        });

        return combinedResults;
    }
}