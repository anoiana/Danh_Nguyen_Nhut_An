// app.js
require("dotenv").config();
const express = require("express");
const cors = require("cors");
const morgan = require("morgan");
const connectDB = require("./config/db");

// --- Import Routes ---
const locationRoutes = require("./routes/location.routes");
const productRoutes = require("./routes/product.routes");
const categoryRoutes = require("./routes/category.routes");
const uploadRoutes = require("./routes/upload.routes");
// (productRoutes sẽ được thêm sau)
// const productRoutes = require('./routes/product.routes');

// --- Khởi tạo App ---
const app = express();

// --- Kết nối Database ---
connectDB();

// --- Middlewares ---
app.use(cors());
app.use(morgan("dev"));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// --- Định tuyến (Routing) ---
app.use("/locations", locationRoutes);
app.use("/products", productRoutes);
app.use("/categories", categoryRoutes);
app.use("/uploads", uploadRoutes);
// app.use('/products', productRoutes);

// --- Khởi chạy Server ---
const PORT = process.env.PORT || 3002;
app.listen(PORT, () => {
  console.log(`🚀 CatalogService is running on http://localhost:${PORT}`);
});
