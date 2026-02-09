// controllers/event.controller.js
const eventService = require("../services/event.service");
const cloudinary = require("../config/cloudinary"); // bạn nói đã có sẵn
const streamifier = require("streamifier");
const { syncPricesForEventChange } = require("../services/event.apply.service");

function uploadToCloudinary(buffer, folder = "events") {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      { folder },
      (err, result) => {
        if (err) return reject(err);
        resolve({
          url: result.secure_url,
          public_id: result.public_id,
        });
      }
    );
    streamifier.createReadStream(buffer).pipe(stream);
  });
}

module.exports = {
  async getAll(req, res) {
    try {
      const rows = await eventService.getAll();
      res.json(rows);
    } catch (e) {
      res.status(400).json({ message: e.message });
    }
  },

  async getById(req, res) {
    try {
      const row = await eventService.getById(req.params.id);
      res.json(row);
    } catch (e) {
      res.status(404).json({ message: e.message });
    }
  },

  async create(req, res) {
    try {
      const ev = await eventService.create(req.body);
      await syncPricesForEventChange(ev);
      res.status(201).json(ev);
    } catch (e) {
      res.status(400).json({ message: e.message });
    }
  },

  async update(req, res) {
    try {
      const ev = await eventService.update(req.params.id, req.body);
      await syncPricesForEventChange(ev);
      res.json(ev);
    } catch (e) {
      res.status(400).json({ message: e.message });
    }
  },

  async delete(req, res) {
    try {
      const ev = await eventService.deleteHard(req.params.id);
      await syncPricesForEventChange(ev);
      res.json({ message: "Đã xóa event", id: ev._id });
    } catch (e) {
      res.status(400).json({ message: e.message });
    }
  },

  async toggleStatus(req, res) {
    try {
      const ev = await eventService.toggleStatus(req.params.id);
      await syncPricesForEventChange(ev);
      res.json(ev);
    } catch (e) {
      res.status(400).json({ message: e.message });
    }
  },

  // Lấy danh sách sự kiện active cho public
  async getActivePublic(req, res) {
    try {
      const rows = await eventService.getActivePublic();
      res.json(rows);
    } catch (e) {
      res.status(400).json({ message: e.message });
    }
  },

  // Upload ảnh giống ManageLocation: nhận multipart field "file" và trả {url, public_id}
  async uploadImage(req, res) {
    try {
      if (!req.file?.buffer) {
        return res.status(400).json({ message: "Thiếu file ảnh." });
      }
      const out = await uploadToCloudinary(req.file.buffer, "events");
      res.json(out);
    } catch (e) {
      res.status(400).json({ message: e.message || "Upload ảnh thất bại" });
    }
  },
  // Lấy chi tiết sự kiện public theo id hoặc slug
  async getPublicByIdOrSlug(req, res) {
    try {
      const row = await eventService.getPublicByIdOrSlug(req.params.idOrSlug);
      res.json(row);
    } catch (e) {
      res.status(404).json({ message: e.message });
    }
  },
  // Lấy danh sách tour áp dụng sự kiện public theo id hoặc slug
  async getPublicTours(req, res) {
    try {
      const rows = await eventService.getPublicTours(req.params.idOrSlug);
      res.json(rows);
    } catch (e) {
      res.status(400).json({ message: e.message });
    }
  },
  // PUBLIC: lấy tất cả event trong tháng (theo month 1-12)
  async getPublicEventsInMonth(req, res) {
    try {
      const now = new Date();
      const year = Number(req.query.year) || now.getFullYear();
      const month = Number(req.query.month) || now.getMonth() + 1; // 1-12

      const rows = await eventService.getPublicEventsInMonth(year, month);
      res.json(rows);
    } catch (e) {
      res.status(400).json({ message: e.message });
    }
  },
  async forceSyncPrices(req, res) {
    try {
      const ev = await eventService.getById(req.params.id);
      const result = await syncPricesForEventChange(ev);
      res.json({ ok: true, event_id: ev._id, ...result });
    } catch (e) {
      res.status(400).json({ ok: false, message: e.message });
    }
  },
};
