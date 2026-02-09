// controllers/inventory.controller.js
const inventoryService = require('../services/inventory.service');

class InventoryController {

  async createInventory(req, res) {
    try {
      // (Chúng ta có thể check quyền sở hữu partnerId (từ token) 
      // với product_id (từ Catalog) ở đây nếu cần)
      
      const item = await inventoryService.createInventory(req.body);
      res.status(201).json(item);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }

  async getInventoryForProduct(req, res) {
    try {
      const items = await inventoryService.getInventoryForProduct(req.params.productId, req.query);
      res.status(200).json(items);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }

  async updateInventory(req, res) {
    try {
      const item = await inventoryService.updateInventory(req.params.id, req.body);
      res.status(200).json(item);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }

  async deleteInventory(req, res) {
    try {
      const result = await inventoryService.deleteInventory(req.params.id);
      res.status(200).json(result);
    } catch (error) {
      res.status(404).json({ message: error.message });
    }
  }

  // POST /inventory/check
  async checkStock(req, res) {
    try {
      const { items } = req.body;
      if (!items || !Array.isArray(items)) {
        return res.status(400).json({ message: 'Invalid input: "items" array is required' });
      }
      
      await inventoryService.checkStock(items);
      // Nếu không ném lỗi, nghĩa là hàng có sẵn
      res.status(200).json({ isAvailable: true });
      
    } catch (error) {
      // Báo lỗi 400 (Bad Request) nếu không đủ hàng
      res.status(400).json({ isAvailable: false, message: error.message });
    }
  }

  // POST /inventory/reserve
  async reserveStock(req, res) {
    try {
      const { items } = req.body;
      if (!items || !Array.isArray(items)) {
        return res.status(400).json({ message: 'Invalid input: "items" array is required' });
      }

      const result = await inventoryService.reserveStock(items);
      res.status(200).json(result);
    } catch (error) {
      // Lỗi 500 (Internal Server Error) nếu giao dịch thất bại
      res.status(500).json({ success: false, message: 'Stock reservation failed', error: error.message });
    }
  }

  // POST /inventory/release
  async releaseStock(req, res) {
    try {
      const { items } = req.body;
      if (!items || !Array.isArray(items)) {
        return res.status(400).json({ message: 'Invalid input: "items" array is required' });
      }

      const result = await inventoryService.releaseStock(items);
      res.status(200).json(result);
    } catch (error) {
      res.status(500).json({ success: false, message: 'Stock release failed', error: error.message });
    }
  }

  async getInventoryInternal(req, res) {
    try {
      const result = await inventoryService.getInventoryInternal(req.params.id);
      res.status(200).json(result);
    } catch (error) {
      res.status(404).json({ message: error.message });
    }
  }
}

module.exports = new InventoryController();