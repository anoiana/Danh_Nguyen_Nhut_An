// services/inventory.service.js
const InventoryItem = require('../models/inventory.model');
const mongoose = require('mongoose');

class InventoryService {

  /**
   * Tạo một mục tồn kho (mở bán Tour/Hotel/Flight)
   * @param {object} data - Dữ liệu từ controller
   */
  async createInventory(data) {
    // Logic quan trọng: Dựa vào 'product_type' để chuẩn hóa dữ liệu
    const { product_type, product_id, price } = data;

    let inventoryData = {
      product_id,
      product_type,
      price,
      is_active: data.is_active !== undefined ? data.is_active : true,
    };

    if (product_type === 'tour') {
      if (!data.tour_details) throw new Error('tour_details is required for tour');
      
      // [CẬP NHẬT] Map đầy đủ trường transport_schedule từ request vào DB
      inventoryData.tour_details = {
        date: new Date(data.tour_details.date),
        total_slots: data.tour_details.total_slots,
        booked_slots: 0,
        // Dữ liệu vận chuyển (Giờ đi, giờ về, mã chuyến bay...)
        transport_schedule: data.tour_details.transport_schedule || {} 
      };

    } else if (product_type === 'hotel') {
      if (!data.hotel_details) throw new Error('hotel_details is required for hotel');
      inventoryData.hotel_details = {
        room_type_id: data.hotel_details.room_type_id,
        room_name: data.hotel_details.room_name,
        date: new Date(data.hotel_details.date),
        total_allotment: data.hotel_details.total_allotment,
        booked_allotment: 0,
      };
    } else if (product_type === 'flight') {
      if (!data.flight_details) throw new Error('flight_details is required for flight');
      inventoryData.flight_details = {
        flight_code: data.flight_details.flight_code,
        departure_time_utc: new Date(data.flight_details.departure_time_utc),
        arrival_time_utc: new Date(data.flight_details.arrival_time_utc),
        seat_class: data.flight_details.seat_class,
        total_seats: data.flight_details.total_seats,
        booked_seats: 0,
      };
    } else {
      throw new Error('Invalid product_type');
    }

    const inventoryItem = new InventoryItem(inventoryData);
    await inventoryItem.save();
    return inventoryItem;
  }

  /**
   * Lấy tất cả tồn kho cho 1 sản phẩm (từ Catalog)
   * @param {string} productId - ID của Product (từ Catalog)
   * @param {object} queryParams - Dùng để lọc (ví dụ: ngày bắt đầu, ngày kết thúc)
   */
  async getInventoryForProduct(productId, queryParams) {
    let filter = {
      product_id: productId,
      is_active: true,
    };

    // (Logic nâng cao): Thêm filter theo ngày nếu cần
    // if (queryParams.startDate && queryParams.endDate) {
    //   filter["tour_details.date"] = { $gte: new Date(queryParams.startDate), $lte: new Date(queryParams.endDate) };
    // }

    return await InventoryItem.find(filter).sort({ "tour_details.date": 1, "hotel_details.date": 1 });
  }

  /**
   * Cập nhật 1 mục tồn kho (ví dụ: Admin sửa giá, sửa tổng số chỗ)
   * @param {string} inventoryId - ID của _InventoryItem_
   * @param {object} updateData
   */
  async updateInventory(inventoryId, updateData) {
    // Rất quan trọng: Không cho phép sửa `booked_slots` bằng tay qua API này.
    // `booked_slots` chỉ được sửa bởi hệ thống (reserveStock).
    if (updateData.tour_details) delete updateData.tour_details.booked_slots;
    if (updateData.hotel_details) delete updateData.hotel_details.booked_allotment;
    if (updateData.flight_details) delete updateData.flight_details.booked_seats;

    // (Bỏ qua `product_id` và `product_type` vì không được sửa)
    delete updateData.product_id;
    delete updateData.product_type;

    const item = await InventoryItem.findByIdAndUpdate(
      inventoryId,
      { $set: updateData },
      { new: true }
    );

    if (!item) {
      throw new Error('Inventory item not found');
    }
    return item;
  }

  /**
   * Xóa 1 mục tồn kho (ví dụ: ngừng bán ngày đó)
   * @param {string} inventoryId
   */
  async deleteInventory(inventoryId) {
    // Xóa mềm (Soft delete)
    const item = await InventoryItem.findByIdAndUpdate(
      inventoryId,
      { is_active: false },
      { new: true }
    );

    if (!item) {
      throw new Error('Inventory item not found');
    }
    return { message: 'Inventory item deactivated' };
  }

  /**
   * [Nội bộ] Kiểm tra xem các_mục hàng có đủ tồn kho không
   * @param {Array} items - Mảng [{ inventoryId, quantity }]
   */
  async checkStock(items) {
    if (!items || items.length === 0) {
      throw new Error('No items to check');
    }

    // 1. Lấy ID và tạo Map số lượng yêu cầu
    const inventoryIds = items.map(item => item.inventoryId);
    const requestedMap = new Map(items.map(item => [item.inventoryId, item.quantity]));

    // 2. Lấy tất cả mục tồn kho từ DB trong 1 lần gọi
    const dbItems = await InventoryItem.find({ _id: { $in: inventoryIds } });

    if (dbItems.length !== items.length) {
      throw new Error('One or more inventory items not found');
    }

    // 3. Kiểm tra từng mục
    for (const dbItem of dbItems) {
      const requestedQty = requestedMap.get(dbItem._id.toString());
      let availableStock = 0;

      if (dbItem.product_type === 'tour') {
        availableStock = dbItem.tour_details.total_slots - dbItem.tour_details.booked_slots;
      } else if (dbItem.product_type === 'hotel') {
        availableStock = dbItem.hotel_details.total_allotment - dbItem.hotel_details.booked_allotment;
      } else if (dbItem.product_type === 'flight') {
        availableStock = dbItem.flight_details.total_seats - dbItem.flight_details.booked_seats;
      } else {
        throw new Error(`Unknown product type in inventory: ${dbItem.product_type}`);
      }

      // Kiểm tra quan trọng
      if (availableStock < requestedQty) {
        throw new Error(`Not enough stock for item ${dbItem._id}. Available: ${availableStock}, Requested: ${requestedQty}`);
      }
    }

    return { isAvailable: true };
  }

  /**
   * [Nội bộ] Giữ chỗ (Tăng số lượng đã đặt)
   * @param {Array} items - Mảng [{ inventoryId, quantity }]
   */
  async reserveStock(items) {
    try {
      for (const item of items) {
        const { inventoryId, quantity } = item;

        // 1. Tìm mục tồn kho
        const invItem = await InventoryItem.findById(inventoryId);
        if (!invItem) {
          throw new Error(`Inventory item ${inventoryId} not found`);
        }

        let updateField;
        let availableStock;

        // 2. Kiểm tra tồn kho lần cuối
        if (invItem.product_type === 'tour') {
          updateField = 'tour_details.booked_slots';
          availableStock = invItem.tour_details.total_slots - invItem.tour_details.booked_slots;
        } else if (invItem.product_type === 'hotel') {
          updateField = 'hotel_details.booked_allotment';
          availableStock = invItem.hotel_details.total_allotment - invItem.hotel_details.booked_allotment;
        } else if (invItem.product_type === 'flight') {
          updateField = 'flight_details.booked_seats';
          availableStock = invItem.flight_details.total_seats - invItem.flight_details.booked_seats;
        }

        if (availableStock < quantity) {
          throw new Error(`Not enough stock for ${invItem._id} during reservation`);
        }

        // 3. Cập nhật
        await InventoryItem.updateOne(
          { _id: inventoryId },
          { $inc: { [updateField]: quantity } }
        );
      }

      return { success: true };

    } catch (error) {
      console.error("Reserve Stock Error:", error);
      throw error;
    }
  }

  /**
   * [Nội bộ] Nhả chỗ
   */
  async releaseStock(items) {
    try {
      for (const item of items) {
        const { inventoryId, quantity } = item;

        const invItem = await InventoryItem.findById(inventoryId);
        if (!invItem) {
          console.warn(`Inventory item ${inventoryId} not found during release`);
          continue;
        }

        let updateField;
        if (invItem.product_type === 'tour') {
          updateField = 'tour_details.booked_slots';
        } else if (invItem.product_type === 'hotel') {
          updateField = 'hotel_details.booked_allotment';
        } else if (invItem.product_type === 'flight') {
          updateField = 'flight_details.booked_seats';
        }

        await InventoryItem.updateOne(
          { _id: inventoryId },
          { $inc: { [updateField]: -quantity } }
        );
      }

      return { success: true };

    } catch (error) {
      console.error("Release Stock Error:", error);
      throw error;
    }
  }

  async getInventoryInternal(id) {
    const item = await InventoryItem.findById(id);
    if (!item) throw new Error("Inventory item not found");
    
    // Trả về ngày khởi hành (chỉ áp dụng cho Tour)
    return {
      _id: item._id,
      date: item.tour_details?.date || null,
      product_type: item.product_type
    };
  }

}

module.exports = new InventoryService();