const mongoose = require("mongoose");

const MessageSchema = new mongoose.Schema(
  {
    role: {
      type: String,
      enum: ["user", "assistant", "system"],
      required: true,
    },
    content: { type: String, required: true },
  },
  { _id: false, timestamps: true }
);

const ChatSessionSchema = new mongoose.Schema(
  {
    sessionId: { type: String, index: true, unique: true },
    messages: { type: [MessageSchema], default: [] },
  },
  { timestamps: true }
);

module.exports = mongoose.model("ChatSession", ChatSessionSchema);
