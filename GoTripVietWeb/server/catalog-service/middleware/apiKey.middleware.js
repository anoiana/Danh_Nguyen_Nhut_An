const apiKeyAuth = (req, res, next) => {
  const providedKey = req.headers['x-api-key'];
  const internalKey = process.env.INTERNAL_API_KEY;

  // --- LOG DEBUG (Quan trọng để tìm lỗi) ---
  console.log(`🔐 [API Key Check]`);
  console.log(`   - Nhận được: '${providedKey}'`);
  console.log(`   - Server mong đợi: '${internalKey}'`);

  if (!internalKey) {
    console.error("❌ CHƯA CẤU HÌNH INTERNAL_API_KEY trong .env");
    return res.status(500).json({ message: 'Server Config Error' });
  }

  if (!providedKey || providedKey !== internalKey) {
    console.warn(`⛔ TỪ CHỐI! Key không khớp.`);
    return res.status(401).json({ message: 'Unauthorized: Invalid Internal API Key' });
  }

  next();
};

module.exports = apiKeyAuth;