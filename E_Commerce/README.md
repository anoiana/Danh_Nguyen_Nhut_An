# 🛒 E-Commerce Full-Stack Project

A robust and scalable E-Commerce platform built with **Spring Boot 3** and **Vanilla JavaScript**, featuring a modern administrative dashboard and a secure customer shopping experience.

---

## 🛠 Tech Stack & Architecture

### **Backend (Core Engine)**
- **Framework:** Spring Boot 3.5.4 (Java 17)
- **Security:** Spring Security + JWT (JSON Web Token)
- **Persistence:** Spring Data JPA + MySQL
- **Messaging:** Java Mail Sender (SMTP) for account verification & password reset.
- **File Storage:** Cloudinary integration for dynamic image management.

### **Frontend (Modern Vanilla JS)**
- **Structure:** Pure HTML5 / CSS3 / ES6+ JavaScript (**No Frameworks**).
- **Component System:** Custom-built "Partial Loader" for reusable UI components (Header, Footer, Sidebar).
- **State Management:** Browser `LocalStorage` for Auth tokens and Session persistence.
- **Integration:** RESTful communication using the `Fetch API` with `Async/Await` patterns.
- **Security:** Secure JWT handling via Authorization Headers for protected routes.

---

## 🏗 Database Schema (Key Entities)

- **`User`**: Credentials, roles (ADMIN/CUSTOMER), and address info.
- **`Product`**: Core details, prices, and relationships to Categories/Promotions.
- **`Variant`**: Product sizes and inventory tracking.
- **`Order`**: Order lifecycle management (Status: Pending, Shipped, Delivered, etc.).
- **`Promotion` & `Coupon`**: Dynamic discounting system.

---

## ✨ Frontend Excellence (Detailed)

### **1. Modular UI with Partial Loading**
The project uses a custom `loadHTML` utility to dynamically inject reusable components like `_header.html` and `_sidebar.html`. This ensures a DRY (Don't Repeat Yourself) architecture while maintaining fast page loads.

### **2. Intelligent User Session Management**
- **Auto-Sync:** The UI automatically reflects login states (swapping Login buttons for User Profiles/Avatars).
- **Role-Based UI:** Admin links and restricted dashboards are only visible/accessible to authorized users.
- **Global Auth Interceptor:** Every protected API call automatically attaches the JWT from LocalStorage.

### **3. Dynamic Shopping Experience**
- **Real-time Cart Updates:** The cart icon count and total amounts update instantly without page refreshes using asynchronous API calls.
- **Interactive Gallery:** Product details feature a multi-image gallery synchronized with backend Cloudinary data.
- **Smart Checkout:** Integrated Vietnam Provinces API provides a seamless, error-free address selection experience.

### **4. Professional Admin Suite**
- **SPA-like Feel:** The Admin dashboard uses JS to manage content without heavy reloading.
- **Toast Notifications:** Real-time feedback for CRUD operations (Create/Update/Delete).
- **Image Management:** Seamless integration with Cloudinary for product image previews and uploads.

---

## 🔐 Security & Authentication Flow

1.  **Registration**: User registers -> Email activation link sent.
2.  **Activation**: Account enabled via `VerificationToken`.
3.  **Login**: JWT Token issued and stored in `LocalStorage`.
4.  **Authorization**: Strict role checks on both Backend (Spring Security) and Frontend (JS Logic).

---

## 🔌 API Endpoints (Quick Reference)

### **Auth API (`/api/auth`)**
- `POST /register`, `GET /confirm`, `POST /login`, `POST /forgot-password`.

### **Shopping API**
- `GET /api/products`: Discover products.
- `GET /api/cart`: Manage personal shopping basket.
- `POST /api/orders`: Place orders with coupon support.

---

## 📂 Installation & Setup

### **Prerequisites**
- JDK 17+ | MySQL 8.0 | Maven
- Cloudinary Account & Gmail App Password

### **Step 1: Database Setup**
```sql
CREATE DATABASE ecommerce CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### **Step 2: Configuration**
- Update `back_end/src/main/resources/application.properties` with your credentials.
- Update `front_end/js/config.js` with your API URL.

### **Step 3: Run**
1.  **Backend**: `./mvnw spring-boot:run`
2.  **Frontend**: Open `front_end/home.html` (Use **Live Server** for full partial support).

---

## 📝 Roadmap
- [ ] Integration with VNPay/Momo.
- [ ] Sales Analytics Charts.
- [ ] Multi-language (i18n).

---
*Developed by: An Danh Nguyen Nhut - 2026*
