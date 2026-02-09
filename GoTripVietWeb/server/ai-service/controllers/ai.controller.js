const asyncHandler = require("../utils/asyncHandler");
const aiService = require("../services/ai.service");

exports.chat = asyncHandler(async (req, res) => {
  const { sessionId, message } = req.body;
  if (!sessionId || !message) {
    return res
      .status(400)
      .json({ message: "sessionId and message are required" });
  }

  const data = await aiService.chat({ sessionId, message });
  res.json(data);
});
