// app.js
require("dotenv").config();
const express = require("express");
const cors = require("cors");
const morgan = require("morgan");
const connectDB = require("./config/db");
const cron = require("node-cron");
const { syncAllPricesNow } = require("./services/event.apply.service");

// --- Import Routes ---
const promotionRoutes = require("./routes/promotion.routes");
const inventoryRoutes = require("./routes/inventory.routes");
const eventRoutes = require("./routes/event.routes");

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
app.use((req, res, next) => {
  console.log("INVENTORY HIT:", req.method, req.originalUrl);
  next();
});
app.use("/promotions", promotionRoutes);
app.use("/inventory", inventoryRoutes);
app.use("/events", eventRoutes);
// --- Cron Job: Đồng bộ giá theo event mỗi ngày lúc 00:05 ---
cron.schedule("5 0 * * *", async () => {
  try {
    await syncAllPricesNow();
    console.log("[CRON] Synced event prices OK");
  } catch (e) {
    console.error("[CRON] Sync event prices FAIL:", e.message);
  }
});

// --- Khởi chạy Server ---
const PORT = process.env.PORT || 3003;
app.listen(PORT, () => {
  console.log(`🚀 InventoryService is running on http://localhost:${PORT}`);
});
