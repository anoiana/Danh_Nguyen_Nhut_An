// middleware/apiKey.middleware.js
const API_KEY = process.env.INTERNAL_API_KEY;

const apiKeyAuth = (req, res, next) => {
  const providedKey = req.headers['x-api-key'];

  if (!providedKey || providedKey !== API_KEY) {
    return res.status(401).json({ message: 'Unauthorized: Invalid API Key' });
  }
  
  next();
};

module.exports = apiKeyAuth;