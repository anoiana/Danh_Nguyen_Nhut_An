// app.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const connectDB = require('./config/db');

// 👇 [MỚI] 1. Import Cron Job Tự động Hoàn thành Tour
const startCompletedCheckCron = require('./cron/completedCheck.cron');

const bookingRoutes = require('./routes/booking.routes');

const app = express();

// 2. Kết nối Database
connectDB();

// 👇 [MỚI] 3. Kích hoạt Cron Job
// Hệ thống sẽ bắt đầu chạy ngầm để quét các tour đã kết thúc
startCompletedCheckCron();

app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// Định tuyến
app.use('/bookings', bookingRoutes);

const PORT = process.env.PORT || 3004;
app.listen(PORT, () => {
  console.log(`🚀 BookingService is running on http://localhost:${PORT}`);
});