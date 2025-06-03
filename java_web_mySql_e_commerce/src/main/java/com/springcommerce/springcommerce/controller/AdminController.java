package com.springcommerce.springcommerce.controller;

import com.springcommerce.springcommerce.entity.Product;
import com.springcommerce.springcommerce.service.ProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.io.IOException;
import java.util.List;

@Controller
@RequestMapping("/admin")
public class AdminController {

    @Autowired
    private ProductService productService;

    // Trang chính của admin
    @GetMapping
    public String home() {
        return "admin/admin"; // Trả về template admin/admin.html
    }

    // Mở form thêm sản phẩm
    @GetMapping("/products/add-product")
    public String addProductForm() {
        return "admin/add-product"; // Trả về template add-product.html
    }

    // Xử lý khi thêm sản phẩm
    @PostMapping("/products/add-product")
    public String addProduct(@ModelAttribute Product product,
                             @RequestParam("file") MultipartFile file) {
        try {
            productService.addProduct(product, file); // Gọi service để lưu sản phẩm và file ảnh
        } catch (IOException e) {
            e.printStackTrace();
        }
        return "redirect:/admin/products"; // Chuyển hướng về danh sách sản phẩm
    }

    // Hiển thị danh sách sản phẩm
    @GetMapping("/products")
    public String listProducts(Model model) {
        List<Product> products = productService.getAllProducts(); // Lấy danh sách sản phẩm
        model.addAttribute("products", products);
        return "admin/products"; // Trả về template products.html
    }

    // Xóa sản phẩm
    @GetMapping("/products/delete/{id}")
    public String deleteProduct(@PathVariable("id") Long productId) {
        productService.deleteProduct(productId); // Gọi service để xóa sản phẩm
        return "redirect:/admin/products"; // Chuyển hướng về danh sách sản phẩm
    }

    // Hiển thị trang chỉnh sửa sản phẩm
    @GetMapping("/products/edit/{id}")
    public String editProduct(@PathVariable Long id, Model model) {
        Product product = productService.findById(id);
        if (product == null) {
            throw new RuntimeException("Product not found with ID: " + id);
        }

        // Nếu không có ảnh, gán ảnh mặc định
        if (product.getLinkImg() == null || product.getLinkImg().isEmpty()) {
            product.setLinkImg("/images/default-product-image.jpg");
        }

        model.addAttribute("product", product);
        return "admin/edit-product"; // Trả về template edit-product.html
    }

    @PostMapping("/products/edit-product")
    public String updateProduct(@ModelAttribute Product product,
                                @RequestParam(value = "file", required = false) MultipartFile file) {
        try {
            productService.updateProduct(product, file); // Gọi service để cập nhật sản phẩm
        } catch (IOException e) {
            e.printStackTrace(); // Log lỗi nếu xảy ra
        }
        return "redirect:/admin/products"; // Chuyển hướng về danh sách sản phẩm
    }


    @PostMapping("/products/delete-selected")
    public String deleteSelectedProducts(@RequestParam("productIds") List<Long> productIds, RedirectAttributes redirectAttributes) {
        if (productIds != null && !productIds.isEmpty()) {
            productService.deleteProductsByIds(productIds); // Gọi ProductService
            redirectAttributes.addFlashAttribute("message", "Selected products have been deleted successfully.");
        } else {
            redirectAttributes.addFlashAttribute("error", "No products selected for deletion.");
        }
        return "redirect:/admin/products"; // Redirect về trang quản lý sản phẩm
    }


}
