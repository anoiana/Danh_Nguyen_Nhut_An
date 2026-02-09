// services/location.service.js
const Location = require("../models/location.model");
const cloudinary = require("../config/cloudinary");

class LocationService {
  
  async createLocation(data) {
    const location = new Location(data);
    return await location.save();
  }

  async getAllLocations(filter = {}) {
    // Không cần phân trang cho location vì nó ít
    return await Location.find(filter);
  }

  async getLocationByIdOrSlug(identifier) {
    // Kiểm tra xem identifier có phải là ObjectId hợp lệ không
    const isObjectId = mongoose.Types.ObjectId.isValid(identifier);

    let location;
    if (isObjectId) {
      location = await Location.findById(identifier);
    } else {
      location = await Location.findOne({ slug: identifier });
    }

    if (!location) {
      throw new Error("Location not found");
    }
    return location;
  }

  async updateLocation(id, updateData) {
    const current = await Location.findById(id);
    if (!current) throw new Error("Location not found");
    // Chuẩn hóa định dạng ảnh
    const normalizeImage = (img) =>
      typeof img === "string" ? { url: img, public_id: "" } : img;
    // chỉ xử lý nếu client gửi images
    const nextImages = Array.isArray(updateData.images)
      ? updateData.images.map(normalizeImage).filter((i) => i?.url)
      : null;

    if (nextImages) {
      const oldPublicIds = (current.images || [])
        .map((img) => (typeof img === "string" ? "" : img?.public_id || ""))
        .filter(Boolean);

      const newPublicIds = nextImages
        .map((img) => img?.public_id || "")
        .filter(Boolean);

      const removed = oldPublicIds.filter((pid) => !newPublicIds.includes(pid));
      updateData.images = nextImages;
      // xóa trên Cloudinary các ảnh bị remove khỏi Location
      await Promise.all(
        removed.map((pid) =>
          cloudinary.uploader.destroy(pid, {
            resource_type: "image",
            invalidate: true,
          })
        )
      );
    }

    const location = await Location.findByIdAndUpdate(id, updateData, {
      new: true,
      runValidators: true,
    });
    if (!location) throw new Error("Location not found");
    return location;
  }

  async deleteLocation(id) {
    const location = await Location.findByIdAndDelete(id);
    if (!location) throw new Error("Location not found");

    const publicIds = (location.images || [])
      .map((img) => (typeof img === "string" ? "" : img?.public_id || ""))
      .filter(Boolean);

    // ✅ xóa sạch ảnh Cloudinary khi xóa Location
    await Promise.all(
      publicIds.map((pid) =>
        cloudinary.uploader.destroy(pid, {
          resource_type: "image",
          invalidate: true,
        })
      )
    );

    return { message: "Location deleted" };
  }
}

// Cần import mongoose để dùng isValid
const mongoose = require("mongoose");
module.exports = new LocationService();
