// middleware/auth.middleware.js
const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
  try {
    // 1. Lấy token từ header (API Gateway sẽ chuyển tiếp header này)
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Lấy phần 'Bearer <token>'

    if (token == null) {
      return res.status(401).json({ message: 'Unauthorized: No token provided' });
    }

    // 2. Xác thực token
    // (Phải dùng đúng JWT_SECRET trong file .env)
    jwt.verify(token, process.env.JWT_SECRET, (err, userPayload) => {
      if (err) {
        return res.status(403).json({ message: 'Forbidden: Invalid token' });
      }

      // 3. Nếu token hợp lệ, gắn payload (chứa id, email, roles) vào request
      req.user = userPayload;
      
      // 4. Cho phép request đi tiếp
      next();
    });
  } catch (error) {
    res.status(401).json({ message: 'Unauthorized' });
  }
};

module.exports = authMiddleware;