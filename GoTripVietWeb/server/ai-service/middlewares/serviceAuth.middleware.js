const { INTERNAL_API_KEY } = require("../config/env");

module.exports = function serviceAuth(req, res, next) {
  // Nếu chưa set key thì block luôn để tránh “hở”
  if (!INTERNAL_API_KEY) {
    return res
      .status(500)
      .json({ message: "Missing INTERNAL_API_KEY on server" });
  }

  const key = req.headers["x-internal-api-key"];
  if (!key || key !== INTERNAL_API_KEY) {
    return res.status(401).json({ message: "Unauthorized (internal)" });
  }
  next();
};
