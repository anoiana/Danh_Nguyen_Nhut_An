// controllers/product.controller.js
const productService = require("../services/product.service");
const axios = require('axios');

class ProductController {

  // 1. TẠO SẢN PHẨM
  async createProduct(req, res) {
    try {
      // Lấy thông tin User từ token
      const partnerId = req.user.id;
      const userRoles = req.user.roles || [];

      // [CHECK PARTNER APPROVAL] 
      // Nếu là Partner, phải kiểm tra xem account đã được Admin duyệt chưa (gọi qua User Service)
      // Nếu là Admin thì bỏ qua bước này
      if (!userRoles.includes('admin') && userRoles.includes('partner')) {
        try {
          const partnerRes = await axios.get(
            `${process.env.USER_SERVICE_URL}/users/${partnerId}`,
            { headers: { Authorization: req.headers.authorization } }
          );
          const currentUser = partnerRes.data;

          if (!currentUser.partner_details?.is_approved) {
            return res.status(403).json({
              message: "Tài khoản đối tác của bạn chưa được duyệt. Vui lòng chờ Admin phê duyệt."
            });
          }
        } catch (err) {
          console.error("❌ Lỗi gọi User Service:", err.message);
          // Tùy chọn: Có thể return lỗi hoặc cho qua nếu muốn mềm dẻo
          // return res.status(500).json({ message: "Không thể xác thực trạng thái đối tác." });
        }
      }

      // Tiến hành tạo sản phẩm
      // Service sẽ tự động set status='pending' nếu là Partner, 'active' nếu là Admin
      const product = await productService.createProduct(req.body, partnerId, userRoles);

      res.status(201).json(product);

    } catch (error) {
      console.error("❌ Lỗi tạo sản phẩm:", error);
      res.status(400).json({ message: error.message });
    }
  }

  // 2. LẤY SẢN PHẨM CỦA TÔI (PARTNER)
  async getMyProducts(req, res) {
    try {
      const partnerId = req.user.id;
      const userRoles = req.user.roles || [];

      // Truyền partner_id và userRoles để Service trả về cả tour pending/hidden của chính họ
      const result = await productService.getProducts(
        { ...req.query, partner_id: partnerId },
        userRoles,
        partnerId
      );

      res.status(200).json(result.products || []);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }

  // 3. LẤY DANH SÁCH PUBLIC (SEARCH/FILTER) - CHỈ ACTIVE
  async getProducts(req, res) {
    try {
      // Không truyền role -> Service mặc định coi là guest -> Chỉ trả active
      const result = await productService.getProducts(req.query);
      res.status(200).json(result);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }

  // 4. [NEW] LẤY DANH SÁCH CHO ADMIN (QUẢN LÝ TOÀN BỘ)
  async getProductsAdmin(req, res) {
    try {
      // Truyền role admin để lấy tất cả status
      const result = await productService.getProducts(req.query, ["admin"]);
      res.status(200).json(result);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }

  // 5. LẤY CHI TIẾT PUBLIC (CHỈ ACTIVE)
  async getProductByIdOrSlug(req, res) {
    try {
      const product = await productService.getProductByIdOrSlug(
        req.params.idOrSlug
      );
      res.status(200).json(product);
    } catch (error) {
      res.status(404).json({ message: error.message });
    }
  }

  // 6. LẤY CHI TIẾT ADMIN/PARTNER (FULL STATUS)
  async getProductByIdOrSlugAdmin(req, res) {
    try {
      const product = await productService.getProductByIdOrSlugAdmin(
        req.params.idOrSlug
      );
      res.status(200).json(product);
    } catch (error) {
      res.status(404).json({ message: error.message });
    }
  }

  // 7. CẬP NHẬT SẢN PHẨM
  async updateProduct(req, res) {
    try {
      const partnerId = req.user.id;
      const userRoles = req.user.roles || [];
      const productId = req.params.id;

      // Service sẽ tự động reset status về 'pending' nếu là Partner sửa
      const updatedProduct = await productService.updateProduct(
        productId,
        req.body,
        partnerId,
        userRoles
      );
      res.status(200).json(updatedProduct);
    } catch (error) {
      if (error.message.startsWith("Forbidden")) {
        return res.status(403).json({ message: error.message });
      }
      if (error.message.startsWith("Product not found")) {
        return res.status(404).json({ message: error.message });
      }
      res.status(400).json({ message: error.message });
    }
  }

  // 8. [NEW] DUYỆT / TỪ CHỐI TOUR (ADMIN ONLY)
  async updateProductStatus(req, res) {
    try {
      const { id } = req.params;
      const { status, reason } = req.body; // reason bắt buộc nếu status='rejected'

      if (!status) return res.status(400).json({ message: "Status is required" });

      const result = await productService.updateStatus(id, status, reason);
      res.status(200).json(result);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }

  // 9. XÓA SẢN PHẨM
  async deleteProduct(req, res) {
    try {
      const partnerId = req.user.id; // Chỉ dùng để log hoặc check ownership nếu cần thêm logic controller
      const productId = req.params.id;

      // Lưu ý: Logic check quyền sở hữu đang nằm trong Service hoặc bạn có thể check tại đây
      // Ở đây ta gọi service delete, service sẽ check tồn tại. 
      // Nếu muốn chặt chẽ hơn về quyền, nên gọi 1 hàm check owner trước hoặc truyền partnerId vào service delete

      const result = await productService.deleteProduct(productId);
      res.status(200).json(result);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }

  // 10. THÊM LỊCH KHỞI HÀNH (Schedule)
  async addSchedule(req, res) {
    try {
      const partnerId = req.user.id;
      const productId = req.params.id;
      const scheduleData = req.body;

      const updatedProduct = await productService.addSchedule(productId, scheduleData, partnerId);
      res.status(200).json(updatedProduct);
    } catch (error) {
      if (error.message.includes("Forbidden")) return res.status(403).json({ message: error.message });
      if (error.message.includes("not found")) return res.status(404).json({ message: error.message });
      res.status(400).json({ message: error.message });
    }
  }

  // 11. XÓA LỊCH KHỞI HÀNH
  async removeSchedule(req, res) {
    try {
      const partnerId = req.user.id;
      const productId = req.params.id;
      const scheduleId = req.params.scheduleId;

      const updatedProduct = await productService.removeSchedule(productId, scheduleId, partnerId);
      res.status(200).json(updatedProduct);
    } catch (error) {
      if (error.message.includes("Forbidden")) return res.status(403).json({ message: error.message });
      if (error.message.includes("not found")) return res.status(404).json({ message: error.message });
      res.status(400).json({ message: error.message });
    }
  }

  // Thêm hàm này vào Class
  async getProductInternal(req, res) {
    try {
      // Gọi sang Service
      const product = await productService.getProductInternal(req.params.id);
      res.status(200).json(product);
    } catch (error) {
      console.error("❌ Error getting internal product:", error.message);
      res.status(500).json({ message: error.message });
    }
  }
}

module.exports = new ProductController();