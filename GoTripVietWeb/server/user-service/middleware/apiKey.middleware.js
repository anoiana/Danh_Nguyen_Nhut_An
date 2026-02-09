// middleware/apiKey.middleware.js

const apiKeyAuth = (req, res, next) => {
  // 1. Lấy key từ Header gửi đến
  const providedKey = req.headers['x-api-key'];

  // 2. Lấy key chuẩn từ file .env của server này
  const internalKey = process.env.INTERNAL_API_KEY;

  // [QUAN TRỌNG] Kiểm tra xem Server đã cấu hình key chưa
  if (!internalKey) {
    console.error("❌ LỖI NGHIÊM TRỌNG: Chưa cấu hình INTERNAL_API_KEY trong file .env của User Service!");
    return res.status(500).json({ message: 'Server Configuration Error: Missing Internal API Key' });
  }

  // 3. So sánh
  if (!providedKey || providedKey !== internalKey) {
    // In ra log để biết tại sao sai (Rất quan trọng khi debug)
    console.warn(`⛔ [API Key Auth] Từ chối truy cập!`);
    console.warn(`   - Nhận được (từ Payment Service): '${providedKey}'`);
    console.warn(`   - Mong đợi (trong .env User):     '${internalKey}'`);

    return res.status(401).json({ message: 'Unauthorized: Invalid Internal API Key' });
  }

  // 4. Hợp lệ -> Cho qua
  next();
};

module.exports = apiKeyAuth;