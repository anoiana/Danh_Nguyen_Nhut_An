// controllers/promotion.controller.js
const promotionService = require("../services/promotion.service");

class PromotionController {
  async createPromotion(req, res) {
    console.log("CREATE BODY:", req.body);
    try {
      const promotion = await promotionService.createPromotion(req.body);
      console.log("CREATED:", promotion._id);
      res.status(201).json(promotion);
    } catch (error) {
      console.error("CREATE PROMOTION ERROR:", error);
      res.status(400).json({ message: error.message });
    }
  }

  async getAllPromotions(req, res) {
    try {
      const promotions = await promotionService.getAllPromotions();
      res.status(200).json(promotions);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }

  async getPromotionByCode(req, res) {
    try {
      const promotion = await promotionService.getPromotionByCode(
        req.params.code
      );
      res.status(200).json(promotion);
    } catch (error) {
      res.status(404).json({ message: error.message });
    }
  }

  async updatePromotion(req, res) {
    try {
      const promotion = await promotionService.updatePromotion(
        req.params.id,
        req.body
      );
      res.status(200).json(promotion);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }

  async deletePromotion(req, res) {
    try {
      const result = await promotionService.deletePromotion(req.params.id);
      res.status(200).json(result);
    } catch (error) {
      res.status(404).json({ message: error.message });
    }
  }

  async toggleStatus(req, res) {
    try {
      const { id } = req.params;
      const promotion = await promotionService.toggleStatus(id);
      res.json(promotion);
    } catch (e) {
      res.status(400).json({ message: e.message });
    }
  }

  async getActivePromotions(req, res) {
    try {
      const promos = await promotionService.getActivePromotions();
      res.status(200).json(promos);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }

  async redeemPromotion(req, res) {
    try {
      const { id } = req.body;
      if (!id) throw new Error("Promotion ID is required");
      const promo = await promotionService.redeemPromotion(id);
      res.status(200).json({ status: "success", promotion: promo });
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }
}

module.exports = new PromotionController();
