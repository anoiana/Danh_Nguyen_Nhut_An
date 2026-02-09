// config/env.js
require("dotenv").config();

module.exports = {
  PORT: process.env.PORT || 3010,
  NODE_ENV: process.env.NODE_ENV || "development",
  MONGO_URI: process.env.MONGO_URI,
  CATALOG_SERVICE_URL: process.env.CATALOG_SERVICE_URL,
  INVENTORY_SERVICE_URL: process.env.INVENTORY_SERVICE_URL,
  INTERNAL_API_KEY: process.env.INTERNAL_API_KEY || "",
  // OLLAMA
  OLLAMA_URL: process.env.OLLAMA_URL || "http://localhost:11434",
  OLLAMA_CHAT_MODEL: process.env.OLLAMA_CHAT_MODEL || "llama3.1:8b",
  OLLAMA_EMBED_MODEL: process.env.OLLAMA_EMBED_MODEL || "nomic-embed-text",
  // Qdrant
  QDRANT_URL: process.env.QDRANT_URL || "http://localhost:6333",
  QDRANT_COLLECTION: process.env.QDRANT_COLLECTION || "gotripviet_tours",
};
