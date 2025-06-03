package com.springcommerce.springcommerce.entity;

import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects; // Thêm import này

@Entity
@Table(name = "customer") // Thêm @Table để rõ ràng hơn, tùy chọn
public class Customer {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long userId;

    private String name;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(nullable = false) // Mật khẩu không nên null
    private String password;

    // Thêm trường roles cho Spring Security
    @Column(name = "roles", nullable = false, columnDefinition = "VARCHAR(255) DEFAULT 'USER'")
    private String roles = "USER"; // Mặc định là USER

    @OneToMany(mappedBy = "customer", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<CartCustomers> cartCustomers = new ArrayList<>();

    // Constructors (Thêm constructor nếu cần)
    public Customer() {
    }

    public Customer(String name, String email, String password, String roles) {
        this.name = name;
        this.email = email;
        this.password = password;
        this.roles = roles;
    }

    // Getters and Setters
    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getRoles() {
        return roles;
    }

    public void setRoles(String roles) {
        this.roles = roles;
    }

    public List<CartCustomers> getCartCustomers() {
        return cartCustomers;
    }

    public void setCartCustomers(List<CartCustomers> cartCustomers) {
        this.cartCustomers = cartCustomers;
    }

    // Phương thức tiện ích để quản lý mối quan hệ hai chiều với CartCustomers
    public void addCart(Cart cart) {
        // Kiểm tra nếu Cart đã được liên kết với Customer này thông qua CartCustomers
        for (CartCustomers existingCartCustomer : this.cartCustomers) {
            if (existingCartCustomer.getCart().getIdCart().equals(cart.getIdCart()) &&
                    existingCartCustomer.getCustomer().getUserId().equals(this.getUserId())) {
                return; // Nếu đã có, không làm gì cả
            }
        }

        // Tạo một CartCustomers mới để liên kết
        CartCustomers newCartCustomer = new CartCustomers();
        newCartCustomer.setCustomer(this); // Thiết lập Customer hiện tại
        newCartCustomer.setCart(cart);     // Thiết lập Cart được truyền vào

        this.cartCustomers.add(newCartCustomer); // Thêm vào danh sách của Customer
        // cart.getCartCustomers().add(newCartCustomer); // Nếu CartCustomers cũng có tham chiếu ngược lại Cart
    }

    public void removeCart(Cart cart) {
        this.cartCustomers.removeIf(cc -> cc.getCart().getIdCart().equals(cart.getIdCart()) &&
                cc.getCustomer().getUserId().equals(this.getUserId()));
    }

    // Nên override equals và hashCode nếu bạn làm việc nhiều với các collection hoặc detached entities
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Customer customer = (Customer) o;
        return Objects.equals(userId, customer.userId) &&
                Objects.equals(email, customer.email); // email là unique, có thể dùng để so sánh
    }

    @Override
    public int hashCode() {
        return Objects.hash(userId, email);
    }

    @Override
    public String toString() {
        return "Customer{" +
                "userId=" + userId +
                ", name='" + name + '\'' +
                ", email='" + email + '\'' +
                ", roles='" + roles + '\'' +
                '}';
    }
}