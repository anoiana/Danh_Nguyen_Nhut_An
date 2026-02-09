// routes/event.routes.js
const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/auth.middleware");
const checkRole = require("../middleware/checkRole.middleware");
const eventController = require("../controllers/event.controller");

const multer = require("multer");
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
});

// PUBLIC: active events (không cần auth)
router.get("/active", eventController.getActivePublic);

router.post("/:id/force-sync", eventController.forceSyncPrices);

// PUBLIC: events in a month (không cần auth)
router.get("/public/month", eventController.getPublicEventsInMonth);

// PUBLIC: event detail (by id or slug)
router.get("/public/:idOrSlug", eventController.getPublicByIdOrSlug);

// PUBLIC: tours applied to event
router.get("/public/:idOrSlug/tours", eventController.getPublicTours);

// Admin list + CRUD
router.get("/", authMiddleware, checkRole(["admin"]), eventController.getAll);
router.get(
  "/:id",
  authMiddleware,
  checkRole(["admin"]),
  eventController.getById
);

router.post("/", authMiddleware, checkRole(["admin"]), eventController.create);
router.put(
  "/:id",
  authMiddleware,
  checkRole(["admin"]),
  eventController.update
);
router.delete(
  "/:id",
  authMiddleware,
  checkRole(["admin"]),
  eventController.delete
);

// toggle active/inactive
router.patch(
  "/:id/status",
  authMiddleware,
  checkRole(["admin"]),
  eventController.toggleStatus
);

// upload image (giống ManageLocation)
router.post(
  "/upload-image",
  authMiddleware,
  checkRole(["admin"]),
  upload.single("file"),
  eventController.uploadImage
);

module.exports = router;
