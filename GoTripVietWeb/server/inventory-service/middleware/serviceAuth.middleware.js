// middleware/serviceAuth.middleware.js
const jwt = require("jsonwebtoken");

const JWT_SECRET = process.env.JWT_SECRET;
const API_KEY = process.env.INTERNAL_API_KEY;

const serviceAuthMiddleware = (req, res, next) => {
  const token = req.headers["authorization"];
  const apiKey = req.headers["x-api-key"];

  // --- Ưu tiên 1: Kiểm tra API Key (Service-to-Service) ---
  if (apiKey) {
    if (apiKey === API_KEY) {
      // Đây là cuộc gọi nội bộ (ví dụ: từ Webhook)
      // Chúng ta tin tưởng nó và cho qua.
      return next();
    } else {
      // API Key có gửi, nhưng sai
      return res.status(401).json({ message: "Unauthorized: Invalid API Key" });
    }
  }

  // --- Ưu tiên 2: Kiểm tra JWT Token (User-to-Service) ---
  if (token && token.startsWith("Bearer ")) {
    const userToken = token.split(" ")[1];

    if (!userToken) {
      return res
        .status(401)
        .json({ message: "Unauthorized: No token provided" });
    }

    // Xác thực token
    jwt.verify(userToken, JWT_SECRET, (err, userPayload) => {
      if (err) {
        return res.status(403).json({ message: "Forbidden: Invalid token" });
      }

      // Gắn thông tin user (giống hệt auth.middleware.js)
      req.user = userPayload;
      return next();
    });
  } else {
    // Không có cả 2
    return res
      .status(401)
      .json({ message: "Unauthorized: No token or API key provided" });
  }
};

module.exports = serviceAuthMiddleware;
