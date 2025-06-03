package com.springcommerce.springcommerce.controller;

import com.springcommerce.springcommerce.entity.*;
import com.springcommerce.springcommerce.service.CartService;
import com.springcommerce.springcommerce.service.CustomerService;
import com.springcommerce.springcommerce.service.ProductService;
import jakarta.servlet.http.HttpServletRequest;
// import jakarta.servlet.http.HttpSession; // Không cần HttpSession nếu dùng Spring Security cho login
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder; // Import PasswordEncoder
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
// import org.springframework.web.servlet.mvc.support.RedirectAttributes; // Cân nhắc dùng nếu cần flash attributes

import java.security.Principal; // Import Principal
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/customer")
public class CustomerController {

    @Autowired
    private ProductService productService;

    @Autowired
    private CartService cartService;

    @Autowired
    private CustomerService customerService;

    @Autowired
    private PasswordEncoder passwordEncoder; // Inject PasswordEncoder

    // Helper method để lấy Customer đang đăng nhập
    private Customer getLoggedInCustomer(Principal principal) {
        if (principal != null) {
            return customerService.findByEmail(principal.getName());
        }
        return null;
    }

    // Helper method để lấy Cart của Customer
    private Cart getOrCreateCartForCustomer(Customer customer) {
        if (customer == null) {
            return null; // Hoặc throw exception
        }
        Cart cart = null;
        if (customer.getCartCustomers() != null && !customer.getCartCustomers().isEmpty()) {
            for (CartCustomers cartCustomer : customer.getCartCustomers()) {
                cart = cartCustomer.getCart();
                if (cart != null) break; // Lấy giỏ hàng đầu tiên hợp lệ
            }
        }

        if (cart == null) {
            cart = new Cart();
            cartService.saveCart(cart);
            customer.addCart(cart);
            customerService.saveCustomer(customer);
        }
        return cart;
    }


    @GetMapping
    public String showHomePage(@RequestParam(value = "customerId", required = false) Long customerIdParam,
                               Principal principal, Model model) {
        Customer loggedInCustomer = getLoggedInCustomer(principal);

        if (loggedInCustomer != null) {
            model.addAttribute("customerId", loggedInCustomer.getUserId());
            model.addAttribute("customerName", loggedInCustomer.getName());
        } else if (customerIdParam != null) { // Chỉ xử lý customerIdParam nếu không có user đăng nhập
            Customer customerFromParam = customerService.findById(customerIdParam);
            if (customerFromParam != null) {
                model.addAttribute("customerId", customerFromParam.getUserId());
                model.addAttribute("customerName", customerFromParam.getName());
            } else {
                // Không nên set error ở đây vì trang chủ có thể xem mà không cần login
                // model.addAttribute("error", "Customer not found");
            }
        }

        List<Product> fashionProducts = productService.getProductsByCategoryName("Man & Woman Fashion");
        List<Product> electronicProducts = productService.getProductsByCategoryName("Electronic");
        List<Product> jewelleryProducts = productService.getProductsByCategoryName("Jewellery Accessories");

        model.addAttribute("fashionGroupedProducts", groupProducts(fashionProducts));
        model.addAttribute("electronicGroupedProducts", groupProducts(electronicProducts));
        model.addAttribute("jewelleryGroupedProducts", groupProducts(jewelleryProducts));

        return "customer/customer";
    }


    private List<List<Product>> groupProducts(List<Product> products) {
        List<List<Product>> groupedProducts = new ArrayList<>();
        int groupSize = 3;
        for (int i = 0; i < products.size(); i += groupSize) {
            groupedProducts.add(products.subList(i, Math.min(i + groupSize, products.size())));
        }
        return groupedProducts;
    }

    @GetMapping("/fashion")
    public String showFashionPage(Model model, Principal principal) {
        Customer loggedInCustomer = getLoggedInCustomer(principal);
        if (loggedInCustomer != null) {
            model.addAttribute("customerId", loggedInCustomer.getUserId());
            model.addAttribute("customerName", loggedInCustomer.getName());
        }
        List<Product> fashionProducts = productService.getProductsByCategoryName("Man & Woman Fashion");
        model.addAttribute("fashionGroupedProducts", groupProducts(fashionProducts));
        return "customer/fashion";
    }

    @GetMapping("/electronic")
    public String showElectronicPage(Model model, Principal principal) {
        Customer loggedInCustomer = getLoggedInCustomer(principal);
        if (loggedInCustomer != null) {
            model.addAttribute("customerId", loggedInCustomer.getUserId());
            model.addAttribute("customerName", loggedInCustomer.getName());
        }
        List<Product> electronicProducts = productService.getProductsByCategoryName("Electronic");
        model.addAttribute("electronicGroupedProducts", groupProducts(electronicProducts));
        return "customer/electronic";
    }

    @GetMapping("/jewellery")
    public String showJewelleryPage(Model model, Principal principal) {
        Customer loggedInCustomer = getLoggedInCustomer(principal);
        if (loggedInCustomer != null) {
            model.addAttribute("customerId", loggedInCustomer.getUserId());
            model.addAttribute("customerName", loggedInCustomer.getName());
        }
        List<Product> jewelleryProducts = productService.getProductsByCategoryName("Jewellery Accessories");
        model.addAttribute("jewelleryGroupedProducts", groupProducts(jewelleryProducts));
        return "customer/jewellery";
    }

    @GetMapping("/detailProduct")
    public String productDetail(
            @RequestParam("id") Long productId,
            // @RequestParam(value = "customerId", required = false) Long customerId, // Lấy customerId từ Principal
            Principal principal,
            Model model) {
        Product product = productService.findById(productId);
        if (product == null) {
            // model.addAttribute("error", "Product not found with ID: " + productId);
            // return "error-page"; // Hoặc một trang lỗi chung
            throw new RuntimeException("Product not found with ID: " + productId); // Hoặc redirect về trang trước với thông báo
        }

        if (product.getLinkImg() == null || product.getLinkImg().isEmpty()) {
            product.setLinkImg("/images/default-product-image.jpg");
        }
        model.addAttribute("product", product);

        Customer loggedInCustomer = getLoggedInCustomer(principal);
        if (loggedInCustomer != null) {
            model.addAttribute("customerId", loggedInCustomer.getUserId());
        }

        return "customer/detailProduct";
    }


    @GetMapping("/cart/add")
    public String addToCart(@RequestParam("productId") Long productId,
                            // @RequestParam(value = "customerId", required = false) Long customerId, // Lấy customerId từ Principal
                            Principal principal,
                            Model model) {
        Customer customer = getLoggedInCustomer(principal);
        if (customer == null) {
            // Spring Security sẽ tự động chuyển hướng đến login nếu endpoint này yêu cầu authenticated
            // Nếu không, bạn có thể chuyển hướng thủ công:
            return "redirect:/customer/login?source=cartAdd&productId=" + productId;
        }

        Cart cart = getOrCreateCartForCustomer(customer);
        if (cart == null) {
            model.addAttribute("error", "Could not create or retrieve cart.");
            return "redirect:/error"; // Hoặc trang nào đó hiển thị lỗi
        }

        Product product = productService.findById(productId);
        if (product == null) {
            model.addAttribute("error", "Product not found");
            return "redirect:/error"; // Điều hướng đến trang lỗi
        }

        cart.addProduct(product); // Logic addProduct trong Cart entity cần xử lý quantity
        cartService.saveCart(cart);

        return "redirect:/customer/cart/view"; // Không cần customerId nữa nếu lấy từ Principal
    }


    @GetMapping("/cart/view")
    public String viewCart(Principal principal, Model model, HttpServletRequest request) { // Sử dụng Model thay vì HttpServletRequest
        Customer customer = getLoggedInCustomer(principal);
        if (customer == null) {
            return "redirect:/customer/login?source=cartView";
        }

        Cart cart = getOrCreateCartForCustomer(customer);
        if (cart == null) { // Trường hợp này không nên xảy ra nếu getOrCreateCartForCustomer hoạt động đúng
            model.addAttribute("error", "Cart not found for customer.");
            return "customer/cart-empty"; // Hoặc một trang lỗi
        }


        if (cart.getCartProducts() == null || cart.getCartProducts().isEmpty()) {
            model.addAttribute("message", "Your cart is empty!");
            model.addAttribute("customerId", customer.getUserId()); // Vẫn cần customerId cho các link khác trên trang
            return "customer/cart-empty";
        }

        double totalPrice = 0.0;
        long totalQuantity = 0;
        for (CartProduct cartProduct : cart.getCartProducts()) {
            totalPrice += cartProduct.getProduct().getPrice() * cartProduct.getQuantity();
            totalQuantity += cartProduct.getQuantity();
        }

        model.addAttribute("cart", cart);
        model.addAttribute("totalPrice", totalPrice);
        model.addAttribute("totalQuantity", totalQuantity);
        model.addAttribute("customerId", customer.getUserId());

        return "customer/cart";
    }


    @GetMapping("/cart/remove")
    public String removeProduct(@RequestParam("productId") Long productId,
                                // @RequestParam("customerId") Long customerId, // Lấy từ Principal
                                Principal principal,
                                Model model) {
        Customer customer = getLoggedInCustomer(principal);
        if (customer == null) {
            return "redirect:/customer/login?source=cartRemove&productId=" + productId;
        }

        Cart cart = getOrCreateCartForCustomer(customer); // Lấy giỏ hàng của customer
        if (cart == null || cart.getCartProducts().isEmpty()) {
            model.addAttribute("message", "Your cart is empty or not found!");
            // Nên redirect về trang view cart để nó xử lý hiển thị cart-empty
            return "redirect:/customer/cart/view";
        }

        cartService.removeProductFromCart(cart, productId); // Service này cần được cập nhật để làm việc với Cart object

        return "redirect:/customer/cart/view";
    }


    @PostMapping("/cart/updateQuantity")
    @ResponseBody
    public ResponseEntity<?> updateCartProductQuantity(@RequestBody Map<String, Object> payload, Principal principal) {
        Customer customer = getLoggedInCustomer(principal);
        if (customer == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("User not authenticated.");
        }

        try {
            Object cartIdObj = payload.get("cartId"); // cartId này phải là của customer đang đăng nhập
            Object productIdObj = payload.get("productId");
            Object quantityObj = payload.get("quantity");

            if (cartIdObj == null || productIdObj == null || quantityObj == null) {
                return ResponseEntity.badRequest().body("Invalid payload: Missing cartId, productId, or quantity.");
            }

            Long cartIdFromPayload = Long.parseLong(cartIdObj.toString());
            Long productId = Long.parseLong(productIdObj.toString());
            int quantity = Integer.parseInt(quantityObj.toString());

            // Xác thực cartId thuộc về customer hiện tại
            Cart customerCart = getOrCreateCartForCustomer(customer);
            if (customerCart == null || !customerCart.getIdCart().equals(cartIdFromPayload)) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Cart ID does not belong to the authenticated user.");
            }


            cartService.updateProductQuantity(cartIdFromPayload, productId, quantity);

            return ResponseEntity.ok("Product quantity in cart updated successfully");
        } catch (NumberFormatException ex) {
            return ResponseEntity.badRequest().body("Invalid payload: cartId, productId, or quantity must be numeric.");
        } catch (Exception ex) {
            // Log the exception
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("An error occurred: " + ex.getMessage());
        }
    }

    @GetMapping("/login")
    public String loginForm(@RequestParam(value = "error", required = false) String error,
                            @RequestParam(value = "logout", required = false) String logout,
                            Model model) {
        if (error != null) {
            model.addAttribute("loginError", "Invalid email or password.");
        }
        if (logout != null) {
            model.addAttribute("logoutMessage", "You have been logged out successfully.");
        }
        // Thêm các thông báo khác từ redirect nếu có
        // if (model.containsAttribute("message")) { ... }
        return "customer/login";
    }

    @PostMapping("/register")
    public String registerCustomer(
            @RequestParam("name") String name,
            @RequestParam("email") String email,
            @RequestParam("password") String password,
            Model model) { // Nên dùng RedirectAttributes để gửi message qua redirect

        if (customerService.findByEmail(email) != null) {
            model.addAttribute("registrationError", "Email already exists!");
            // Không redirect, trả về form đăng ký với lỗi
            // Hoặc nếu trang login và register chung 1 view, thì set attribute và trả về view đó
            return "customer/login"; // Giả sử login và register cùng view, hoặc có link qua lại
        }

        Customer customer = new Customer();
        customer.setName(name);
        customer.setEmail(email);
        customer.setPassword(passwordEncoder.encode(password)); // Mã hóa mật khẩu
        customer.setRoles("USER"); // Gán role mặc định

        // Tạo giỏ hàng mới tự động khi đăng ký
        Cart cart = new Cart();
        cartService.saveCart(cart);
        customer.addCart(cart);

        customerService.saveCustomer(customer);

        // model.addAttribute("message", "Account created successfully! Please login."); // Sẽ mất khi redirect
        // Sử dụng RedirectAttributes thay thế
        // redirectAttributes.addFlashAttribute("registrationSuccess", "Account created successfully! Please login.");
        // Tạm thời vẫn dùng Model, nhưng trang login cần xử lý message này
        model.addAttribute("message", "Account created successfully! Please login.");
        return "customer/login"; // Chuyển hướng về trang login sau khi đăng ký thành công
        // Hoặc "redirect:/customer/login?registrationSuccess=true"
    }


    // Phương thức POST /loginCustomer sẽ được xử lý bởi Spring Security
    // Bạn không cần định nghĩa nó ở đây nữa.
    // Xóa hoặc comment out phương thức loginCustomer cũ.
    /*
    @PostMapping("/loginCustomer")
    public String loginCustomer(
            @RequestParam("email") String email,
            @RequestParam("password") String password,
            HttpSession session,
            Model model) {
        // ... Logic cũ ...
        // Spring Security sẽ xử lý việc này
        return "redirect:/customer"; // Hoặc logic chuyển hướng trong SecurityConfig
    }
    */

    @GetMapping("/search")
    public String searchProducts(
            @RequestParam(name = "search", defaultValue = "All search") String category, // nên là tên category, vd: "Man & Woman Fashion"
            @RequestParam(name = "name", required = false) String keyword, // đổi 'name' thành 'keyword' cho rõ
            Principal principal,
            Model model) {

        Customer loggedInCustomer = getLoggedInCustomer(principal);
        if (loggedInCustomer != null) {
            model.addAttribute("customerId", loggedInCustomer.getUserId());
            model.addAttribute("customerName", loggedInCustomer.getName());
        }

        List<Product> products = new ArrayList<>(); // Khởi tạo để tránh NullPointerException
        if (keyword != null && !keyword.trim().isEmpty()) {
            switch (category.toLowerCase()) { // So sánh không phân biệt hoa thường
                case "name":
                    products = productService.searchProductsByName(keyword);
                    break;
                case "price":
                    try {
                        products = productService.searchByPrice(Double.valueOf(keyword));
                    } catch (NumberFormatException e) {
                        model.addAttribute("searchError", "Invalid price format.");
                    }
                    break;
                case "category":
                    products = productService.getProductsByCategoryName(keyword);
                    break;
                default: // "All search" hoặc không khớp
                    products = productService.searchProductsByNameOrCategory(keyword); // Cần thêm method này vào service
                    break;
            }
        } else if (!"All search".equalsIgnoreCase(category) && (keyword == null || keyword.trim().isEmpty())) {
            // Nếu chọn một category cụ thể nhưng không nhập keyword -> có thể hiểu là xem tất cả sản phẩm của category đó
            products = productService.getProductsByCategoryName(category);
        }
        // else {
        // Nếu là "All search" và không có keyword, có thể trả về danh sách rỗng hoặc tất cả sản phẩm (không khuyến khích)
        // }

        model.addAttribute("searchedProducts", products);
        model.addAttribute("searchCategory", category); // Để giữ lại lựa chọn search
        model.addAttribute("searchKeyword", keyword); // Để giữ lại từ khóa đã nhập
        return "customer/search-results";
    }

    @PostMapping("/cart/payment")
    @ResponseBody
    public ResponseEntity<Map<String, String>> processPayment(@RequestBody Map<String, Object> payload, Principal principal) {
        Customer customer = getLoggedInCustomer(principal);
        if (customer == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "User not authenticated."));
        }

        Long idCartFromPayload;
        try {
            idCartFromPayload = Long.valueOf(payload.get("idCart").toString());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", "Invalid cart ID in payload."));
        }

        // Xác thực cartId thuộc về customer hiện tại
        Cart customerCart = getOrCreateCartForCustomer(customer); // Lấy giỏ hàng hiện tại của customer
        if (customerCart == null || !customerCart.getIdCart().equals(idCartFromPayload)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Cart ID does not match the authenticated user's cart."));
        }

        // Thay vì xóa cart, thường sẽ tạo Order và có thể xóa cart hoặc đánh dấu là đã checkout
        // Hiện tại chỉ xóa cart theo yêu cầu ban đầu
        cartService.deleteCartById(idCartFromPayload); // Đảm bảo service này xóa cả CartCustomers và CartProducts liên quan

        // Tạo lại một giỏ hàng mới cho customer sau khi thanh toán
        // Cart newCart = new Cart();
        // cartService.saveCart(newCart);
        // customer.getCartCustomers().clear(); // Xóa các liên kết cũ
        // customer.addCart(newCart); // Thêm liên kết mới
        // customerService.saveCustomer(customer);

        Map<String, String> response = new HashMap<>();
        response.put("message", "Payment processed (simulated). You will pay offline. Your cart has been cleared.");
        return ResponseEntity.ok(response);
    }
}