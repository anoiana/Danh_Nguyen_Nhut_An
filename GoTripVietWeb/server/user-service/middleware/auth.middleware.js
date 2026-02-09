// middleware/auth.middleware.js
const jwt = require("jsonwebtoken");
const User = require("../models/user.model");

const authMiddleware = (req, res, next) => {
  try {
    const authHeader = req.headers["authorization"];
    const token = authHeader && authHeader.split(" ")[1];

    if (token == null) {
      return res
        .status(401)
        .json({ message: "Unauthorized: No token provided" });
    }

    jwt.verify(token, process.env.JWT_SECRET, async (err, userPayload) => {
      if (err) {
        return res.status(403).json({ message: "Forbidden: Invalid token" });
      }

      // Check status từ DB
      const u = await User.findById(userPayload.id).select("status");
      if (!u)
        return res
          .status(401)
          .json({ message: "Unauthorized: User not found" });

      if (u.status && u.status !== "ACTIVE") {
        return res
          .status(403)
          .json({ message: "Forbidden: Account is not active" });
      }

      req.user = userPayload;
      next();
    });
  } catch (error) {
    res.status(401).json({ message: "Unauthorized" });
  }
};

module.exports = authMiddleware;
