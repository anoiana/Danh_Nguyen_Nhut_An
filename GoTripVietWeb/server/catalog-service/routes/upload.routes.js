const express = require("express");
const multer = require("multer");
const cloudinary = require("../config/cloudinary");

const authMiddleware = require("../middleware/auth.middleware");
const checkRole = require("../middleware/checkRole.middleware");

const router = express.Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
});

router.post(
  "/category-image",
  authMiddleware,
  checkRole(['admin', 'partner']),
  upload.single("file"),
  async (req, res) => {
    try {
      if (!req.file) return res.status(400).json({ message: "Thiếu file" });
      if (!req.file.mimetype.startsWith("image/")) {
        return res.status(400).json({ message: "Chỉ nhận file ảnh" });
      }

      const result = await new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          { folder: "gotripviet/categories", resource_type: "image" },
          (err, out) => (err ? reject(err) : resolve(out))
        );
        stream.end(req.file.buffer);
      });

      return res.json({ url: result.secure_url, public_id: result.public_id });
    } catch (e) {
      console.error(e);
      return res.status(500).json({ message: "Upload thất bại" });
    }
  }
);

router.post(
  "/location-image",
  authMiddleware,
  checkRole(["admin", "partner"]),
  upload.single("file"),
  async (req, res) => {
    try {
      if (!req.file) return res.status(400).json({ message: "Thiếu file" });
      if (!req.file.mimetype.startsWith("image/")) {
        return res.status(400).json({ message: "Chỉ nhận file ảnh" });
      }

      const result = await new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          { folder: "gotripviet/locations", resource_type: "image" },
          (err, out) => (err ? reject(err) : resolve(out))
        );
        stream.end(req.file.buffer);
      });

      return res.json({ url: result.secure_url, public_id: result.public_id });
    } catch (e) {
      console.error(e);
      return res.status(500).json({ message: "Upload thất bại" });
    }
  }
);

router.post(
  "/tour-image",
  authMiddleware,
  checkRole(['admin', 'partner']),
  upload.single("file"),
  async (req, res) => {
    try {
      if (!req.file) return res.status(400).json({ message: "Thiếu file" });
      if (!req.file.mimetype.startsWith("image/")) {
        return res.status(400).json({ message: "Chỉ nhận file ảnh" });
      }

      const result = await new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          { folder: "gotripviet/tours", resource_type: "image" },
          (err, out) => (err ? reject(err) : resolve(out))
        );
        stream.end(req.file.buffer);
      });

      return res.json({ url: result.secure_url, public_id: result.public_id });
    } catch (e) {
      console.error(e);
      return res.status(500).json({ message: "Upload thất bại" });
    }
  }
);

module.exports = router;
