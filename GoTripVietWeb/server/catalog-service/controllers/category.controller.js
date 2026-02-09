const categoryService = require('../services/category.service');
const Category = require('../models/category.model');

// Hàm hỗ trợ tạo slug
const createSlug = (text) => {
  return text.toString().toLowerCase().trim()
    .replace(/\s+/g, "-").replace(/[^\w\-]+/g, "").replace(/\-\-+/g, "-");
};

class CategoryController {

  // [CẬP NHẬT] Request category (Full info)
  async requestCategory(req, res) {
    try {
      // 1. Nhận đầy đủ dữ liệu
      const { name, parent, description, image } = req.body;
      const userId = req.user?._id || req.user?.id;

      if (!name) {
        return res.status(400).json({ message: "Tên danh mục là bắt buộc." });
      }

      // 2. Check trùng
      const existing = await Category.findOne({
        name: { $regex: new RegExp(`^${name.trim()}$`, 'i') }
      });

      if (existing) {
        return res.status(400).json({ message: "Danh mục này đã tồn tại." });
      }

      // 3. Tạo slug
      const slug = createSlug(name);

      // 4. Tạo category với đầy đủ thông tin
      const newCategory = await Category.create({
        name: name.trim(),
        slug: slug,
        description: description || "",
        image: image || "",
        parent: parent || null, // Nếu parent là chuỗi rỗng thì lưu là null
        status: 'pending',
        created_by: userId
      });

      res.status(201).json(newCategory);
    } catch (error) {
      console.error("Request Category Error:", error);
      res.status(500).json({ message: error.message });
    }
  }

  async getAllCategories(req, res) {
    try {
      const userId = req.user?._id || req.user?.id;
      const userRoles = req.user?.roles || [];
      const isAdmin = userRoles.includes('admin');
      const isPartner = userRoles.includes('partner');

      let filter = {};

      if (req.query.parent === "null") filter.parent = null;
      else if (req.query.parent) filter.parent = req.query.parent;

      if (!userId) {
        filter.status = 'active';
      } else {
        if (isAdmin) {
          // Admin xem hết
        } else if (isPartner) {
          const statusFilter = {
            $or: [
              { status: 'active' },
              { created_by: userId }
            ]
          };
          filter = { ...filter, ...statusFilter };
        } else {
          filter.status = 'active';
        }
      }

      const categories = await Category.find(filter)
        .populate("parent", "name slug")
        .sort({ createdAt: -1 }); // Mới nhất lên đầu để dễ thấy cái mới tạo

      res.status(200).json(categories);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }

  async createCategory(req, res) {
    try {
      const category = await categoryService.createCategory(req.body);
      res.status(201).json(category);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }

  async getCategoryByIdOrSlug(req, res) {
    try {
      const category = await categoryService.getCategoryByIdOrSlug(req.params.idOrSlug);
      res.status(200).json(category);
    } catch (error) {
      res.status(404).json({ message: error.message });
    }
  }

  async updateCategory(req, res) {
    try {
      const category = await categoryService.updateCategory(req.params.id, req.body);
      res.status(200).json(category);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  }

  async deleteCategory(req, res) {
    try {
      const result = await categoryService.deleteCategory(req.params.id);
      res.status(200).json(result);
    } catch (error) {
      res.status(404).json({ message: error.message });
    }
  }
}

module.exports = new CategoryController();