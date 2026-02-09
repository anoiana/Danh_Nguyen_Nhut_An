// services/promotion.service.js
const Promotion = require("../models/promotion.model");

class PromotionService {
  async createPromotion(data) {
    const promotion = new Promotion(data);
    return await promotion.save();
  }

  async getAllPromotions() {
    return Promotion.find({}).sort({ createdAt: -1 });
  }

  async getPromotionByCode(code) {
    const promotion = await Promotion.findOne({
      code: code.toUpperCase(),
      is_active: true,
    });
    if (!promotion) {
      throw new Error("Promotion code not found or has expired");
    }
    return promotion;
  }

  async updatePromotion(id, updateData) {
    const promotion = await Promotion.findByIdAndUpdate(id, updateData, {
      new: true,
    });
    if (!promotion) {
      throw new Error("Promotion not found");
    }
    return promotion;
  }

  async deletePromotion(id) {
    const deleted = await Promotion.findByIdAndDelete(id);
    if (!deleted) throw new Error("Không tìm thấy promotion");
    return deleted;
  }

  async toggleStatus(id) {
    const promo = await Promotion.findById(id);
    if (!promo) throw new Error("Không tìm thấy promotion");
    promo.is_active = !promo.is_active;
    await promo.save();
    return promo;
  }

  async getActivePromotions() {
    // Tối thiểu: chỉ lấy is_active=true
    // (nếu schema có start/end date thì lọc thêm ở đây)
    return Promotion.find({ is_active: true }).sort({ createdAt: -1 });
  }

  /**
   * [INTERNAL] Redeem a promotion (increment usage)
   * Called when a booking is confirmed/paid
   */
  async redeemPromotion(id) {
    const promotion = await Promotion.findById(id);

    if (!promotion || !promotion.is_active) {
      throw new Error("Promotion not found or inactive");
    }

    // 1. Check quantity
    if (promotion.used_quantity >= promotion.total_quantity) {
      throw new Error("Mã giảm giá đã hết số lượng sử dụng");
    }

    // 2. Check Expiry
    const now = new Date();
    if (promotion.rules?.valid_to && new Date(promotion.rules.valid_to) < now) {
      throw new Error("Mã giảm giá đã hết hạn");
    }
    if (
      promotion.rules?.valid_from &&
      new Date(promotion.rules.valid_from) > now
    ) {
      throw new Error("Mã giảm giá chưa đến đợt sử dụng");
    }

    // 3. Increment usage
    promotion.used_quantity += 1;
    await promotion.save();

    return promotion;
  }
}

module.exports = new PromotionService();
