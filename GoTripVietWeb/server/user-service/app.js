// app.js
require("dotenv").config(); // Phải gọi đầu tiên để load .env
const express = require("express");
const cors = require("cors");
const morgan = require("morgan");
const connectDB = require("./config/db"); // Import hàm kết nối DB

// --- Import Routes ---
const authRoutes = require("./routes/auth.routes");
const userRoutes = require("./routes/user.routes");

// --- Khởi tạo App ---
const app = express();

// --- Kết nối Database ---
connectDB();

// --- Middlewares ---
app.use(cors()); // Cho phép CORS
app.use(morgan("dev")); // Log request
app.use(express.json()); // Đọc được JSON body
app.use(express.urlencoded({ extended: false }));

// --- Định tuyến (Routing) ---

// Gắn router /auth (Đăng ký, Đăng nhập)
app.use("/auth", authRoutes);

// Gắn router /users (Lấy hồ sơ, Cập nhật)
// API Gateway sẽ gửi các request /users/... đến đây
app.use("/users", userRoutes); // <-- SỬ DỤNG FILE MỚI

// --- Khởi chạy Server ---
const PORT = process.env.PORT || 3001; // Lấy port từ .env
app.listen(PORT, () => {
  console.log(`🚀 UserService is running on http://localhost:${PORT}`);
});
