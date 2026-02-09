// middleware/checkRole.middleware.js

// Hàm này nhận vào một mảng các role được phép (ví dụ: ['admin'])
const checkRole = (roles) => (req, res, next) => {
  // Middleware này phải chạy SAU authMiddleware,
  // nên chúng ta sẽ có req.user
  if (!req.user || !req.user.roles) {
     return res.status(403).json({ message: 'Forbidden: Role not found on token' });
  }

  // Kiểm tra xem user có BẤT KỲ role nào trong mảng roles được phép không
  const hasRole = req.user.roles.some(role => roles.includes(role));

  if (!hasRole) {
    // Nếu không có role hợp lệ
    return res.status(403).json({ message: 'Forbidden: Access denied. Required role not met.' });
  }
  
  // Nếu role hợp lệ, cho đi tiếp
  next();
};

module.exports = checkRole;