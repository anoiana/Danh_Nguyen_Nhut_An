const locationService = require("../services/location.service");
const Location = require("../models/location.model");

// Hàm hỗ trợ tạo slug đơn giản (nếu model chưa có plugin tự động)
const createSlug = (text) => {
  return text
    .toString()
    .toLowerCase()
    .trim()
    .replace(/\s+/g, "-") // Replace spaces with -
    .replace(/[^\w\-]+/g, "") // Remove all non-word chars
    .replace(/\-\-+/g, "-"); // Replace multiple - with single -
};

class LocationController {
  async createLocation(req, res) {
    try {
      const location = await locationService.createLocation(req.body);
      res.status(201).json(location);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }

  // [CẬP NHẬT] Request a new location (Full info)
  async requestLocation(req, res) {
    try {
      // 1. Nhận đầy đủ dữ liệu từ Partner
      const { name, description, country, image } = req.body;
      const userId = req.user?._id || req.user?.id;

      if (!name) {
        return res.status(400).json({ message: "Tên địa điểm là bắt buộc." });
      }

      // 2. Check trùng tên
      const existing = await Location.findOne({
        name: { $regex: new RegExp(`^${name.trim()}$`, "i") },
      });

      if (existing) {
        return res
          .status(400)
          .json({ message: "Địa điểm này đã tồn tại trên hệ thống." });
      }

      // 3. Tạo slug (tạm thời làm thủ công nếu model không tự handle)
      const slug = createSlug(name);

      // 4. Tạo location với đầy đủ thông tin và status 'pending'
      const newLocation = await Location.create({
        name: name.trim(),
        slug: slug,
        description: description || "",
        country: country || "",
        image: image || "", // URL ảnh từ Cloudinary
        status: "pending",
        created_by: userId,
      });

      res.status(201).json(newLocation);
    } catch (error) {
      console.error("Request Location Error:", error);
      res.status(500).json({ message: error.message });
    }
  }

  async getAllLocations(req, res) {
    try {
      const userId = req.user?._id || req.user?.id;
      const userRoles = req.user?.roles || [];
      const isAdmin = userRoles.includes('admin');
      const isPartner = userRoles.includes('partner');

      let filter = { status: 'active' }; // Mặc định cho khách

      if (userId) {
        if (isAdmin) {
          filter = {}; // Admin xem hết
        } else if (isPartner) {
          // Partner xem active + của mình (pending/rejected)
          filter = {
            $or: [
              { status: 'active' },
              { created_by: userId }
            ]
          };
        }
      }

      const locations = await Location.find(filter).sort({ createdAt: -1 });
      res.status(200).json(locations);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }

  async getLocationByIdOrSlug(req, res) {
    try {
      const location = await locationService.getLocationByIdOrSlug(
        req.params.idOrSlug
      );
      res.status(200).json(location);
    } catch (error) {
      res.status(404).json({ message: error.message });
    }
  }

  async updateLocation(req, res) {
    try {
      const location = await locationService.updateLocation(
        req.params.id,
        req.body
      );
      res.status(200).json(location);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }

  async deleteLocation(req, res) {
    try {
      const result = await locationService.deleteLocation(req.params.id);
      res.status(200).json(result);
    } catch (error) {
      res.status(404).json({ message: error.message });
    }
  }
}

module.exports = new LocationController();