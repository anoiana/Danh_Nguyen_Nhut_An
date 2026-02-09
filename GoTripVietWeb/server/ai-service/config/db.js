const mongoose = require("mongoose");
const { MONGO_URI } = require("./env");

async function connectDB() {
  if (!MONGO_URI) throw new Error("Missing MONGO_URI");
  await mongoose.connect(MONGO_URI);
  console.log("AI-service MongoDB connected");
}

module.exports = { connectDB };
