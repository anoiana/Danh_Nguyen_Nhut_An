const Booking = require("../models/booking.model");
const {
  sendPaymentSuccessEmail,
  sendPaidCancellationEmail,
} = require("../utils/mailer");
const axios = require("axios");

// Get URLs from .env
const CATALOG_URL = process.env.CATALOG_SERVICE_URL;
const INVENTORY_URL = process.env.INVENTORY_SERVICE_URL;
const PAYMENT_URL = process.env.PAYMENT_SERVICE_URL;
const API_KEY = process.env.INTERNAL_API_KEY;

class BookingService {
  /**
   * Create a new booking
   * Calculates start_date and end_date for Auto-Complete logic
   */
  async createBooking({
    userId,
    items,
    promotionCode,
    userAuthToken,
    passengers,
    contactInfo,
  }) {
    // --- 1. LẤY DỮ LIỆU THỰC TẾ TỪ CÁC SERVICE KHÁC (SERVER-TO-SERVER) ---
    // Giả sử item đầu tiên là Tour chính để tính ngày giờ
    const mainItemReq = items[0];
    const { productId, inventoryId } = mainItemReq;

    let productData = null;
    let inventoryData = null;

    try {
      // A. Gọi Catalog Service: Lấy Duration & Partner ID
      // API: GET /products/internal/:id
      const prodRes = await axios.get(
        `${CATALOG_URL}/products/internal/${productId}`,
        { headers: { "x-api-key": API_KEY } },
      );
      productData = prodRes.data;
      console.log("---------------- DEBUG LOG ----------------");
      console.log("1. Product ID:", productId);
      console.log(
        "2. Data nhận từ Catalog:",
        JSON.stringify(productData, null, 2),
      );
      console.log(
        "3. Duration Days tìm thấy:",
        productData.tour_details?.duration_days,
      );
      console.log("-------------------------------------------");
      // B. Gọi Inventory Service: Lấy Ngày Khởi Hành (Start Date)
      // API: GET /inventory/internal/:id
      const invRes = await axios.get(
        `${INVENTORY_URL}/inventory/internal/${inventoryId}`,
        { headers: { "x-api-key": API_KEY } },
      );
      inventoryData = invRes.data;
    } catch (err) {
      console.error("❌ Error fetching internal data:", err.message);
      throw new Error("Không thể xác thực thông tin sản phẩm hoặc kho hàng.");
    }

    // --- 2. TÍNH TOÁN NGÀY GIỜ CHUẨN (SOURCE OF TRUTH) ---

    // a. Ngày đi: Lấy từ Inventory DB (Chính xác từng giây)
    const startDate = new Date(inventoryData.date);

    // b. Thời lượng: Lấy từ Product DB (Ví dụ: 3 ngày)
    // Nếu catalog không ghi duration, mặc định là 1 ngày
    const durationDays = parseInt(productData.tour_details?.duration_days);

    // c. Ngày về: Cộng dồn
    const endDate = new Date(startDate);
    endDate.setDate(endDate.getDate() + durationDays);

    console.log(
      `📅 [Booking Logic] Start: ${startDate.toISOString()} | Duration: ${durationDays} days | End: ${endDate.toISOString()}`,
    );

    // --- 3. XỬ LÝ ITEMS & GIÁ (Snapshot) ---
    let totalPrice = 0;
    let formattedItems = [];

    for (const item of items) {
      // Lưu ý: Để an toàn tuyệt đối, bạn cũng nên lấy unitPrice từ inventoryData.price
      // Ở đây tạm thời dùng giá frontend gửi lên (hoặc bạn có thể sửa lại logic này)
      const currentPrice = item.unitPrice;

      totalPrice += currentPrice * item.quantity;
      formattedItems.push({
        product_id: item.productId,
        inventory_id: item.inventoryId,
        product_type: item.productType,
        quantity: item.quantity,
        unit_price: currentPrice,
        snapshot: {
          title: item.productTitle || productData.title, // Ưu tiên lấy title chuẩn
          details_text: item.detailsText,
          image: item.image,
          duration_days: durationDays, // Lưu lại duration vào snapshot
        },
      });
    }

    // --- 4. CHECK STOCK (Kiểm tra tồn kho) ---
    const checkStockRequest = {
      items: items.map((item) => ({
        inventoryId: item.inventoryId,
        quantity: item.quantity,
      })),
    };
    try {
      await axios.post(`${INVENTORY_URL}/inventory/check`, checkStockRequest, {
        headers: { Authorization: userAuthToken },
      });
    } catch (error) {
      throw new Error(
        `Hết hàng hoặc lỗi kho: ${error.response?.data?.message || error.message
        }`,
      );
    }

    // --- 5. HANDLE PROMOTION (Mã giảm giá) ---
    let discountAmount = 0;
    let finalPrice = totalPrice;
    let promotionId = null;

    if (promotionCode) {
      try {
        const promoRes = await axios.get(
          `${INVENTORY_URL}/promotions/code/${promotionCode}`,
        );
        const promotion = promoRes.data;

        if (promotion.rules && promotion.rules.min_spend > totalPrice) {
          throw new Error(
            `Đơn hàng chưa đủ điều kiện tối thiểu: ${promotion.rules.min_spend}`,
          );
        }

        if (promotion.type === "percentage") {
          discountAmount = totalPrice * (promotion.value / 100);
        } else if (promotion.type === "fixed_amount") {
          discountAmount = promotion.value;
        }

        // Không giảm quá giá trị đơn
        if (discountAmount > totalPrice) {
          discountAmount = totalPrice;
        }

        finalPrice = totalPrice - discountAmount;
        promotionId = promotion._id;
      } catch (error) {
        // Nếu mã lỗi thì bỏ qua hoặc báo lỗi tuỳ nghiệp vụ
        console.warn("Promotion Error:", error.message);
        throw new Error(
          `Mã giảm giá không hợp lệ: ${error.response?.data?.message || error.message
          }`,
        );
      }
    }

    // --- 6. TẠO & LƯU BOOKING ---
    const booking = new Booking({
      user_id: userId,
      status: "pending",
      start_date: startDate, // ✅ Dữ liệu chuẩn từ Inventory
      end_date: endDate, // ✅ Dữ liệu chuẩn tính từ Catalog
      items: formattedItems,
      pricing: {
        total_price_before_discount: totalPrice,
        discount_amount: discountAmount,
        final_price: finalPrice,
      },
      promotion_id: promotionId,
      passengers: passengers || [],
      customer_details: contactInfo
        ? {
          fullName: contactInfo.fullName,
          email: contactInfo.email,
          phone: contactInfo.phone,
          address: contactInfo.address,
          note: contactInfo.note,
        }
        : {},
    });

    await booking.save();

    return {
      bookingId: booking._id,
      status: booking.status,
      finalPrice: booking.pricing.final_price,
      paymentUrl: `http://payment-gateway.com/pay?bookingId=${booking._id}`,
    };
  }

  async getBookingsByUserId(userId) {
    return await Booking.find({ user_id: userId }).sort({ createdAt: -1 });
  }

  async getBookingDetails(bookingId, userId) {
    const booking = await Booking.findById(bookingId);
    if (!booking) throw new Error("Booking not found");
    if (booking.user_id.toString() !== userId) {
      throw new Error("Forbidden: You do not own this booking");
    }
    return booking;
  }

  /**
   * Confirm booking (Webhook)
   * Note: This ONLY confirms the booking. Revenue distribution happens later via Cron Job.
   */
  async confirmBooking(bookingId, paymentInfo) {
    const booking = await Booking.findById(bookingId);
    if (!booking) throw new Error("Booking not found");

    if (booking.status !== "pending") {
      if (booking.status === "confirmed") return booking;
      throw new Error(`Booking is already ${booking.status}`);
    }

    // Reserve Stock
    const reserveRequest = {
      items: booking.items.map((item) => ({
        inventoryId: item.inventory_id.toString(),
        quantity: item.quantity,
      })),
    };

    try {
      await axios.post(`${INVENTORY_URL}/inventory/reserve`, reserveRequest, {
        headers: { "x-api-key": API_KEY },
      });
    } catch (error) {
      booking.status = "failed";
      await booking.save();
      throw new Error(
        `Inventory reservation failed: ${error.response?.data?.message || error.message
        }`
      );
    }

    // --- REDEEM PROMOTION (if any) ---
    if (booking.promotion_id) {
      try {
        await axios.post(
          `${INVENTORY_URL}/promotions/internal/redeem`,
          { id: booking.promotion_id },
          { headers: { "x-api-key": API_KEY } }
        );
        console.log(`🎟️ Promotion ${booking.promotion_id} redeemed.`);
      } catch (err) {
        console.error(
          `⚠️ Failed to redeem promotion ${booking.promotion_id}:`,
          err.message
        );
        // Không throw lỗi chết người ở đây vì khách đã trả tiền rồi.
        // Admin sẽ phải check thủ công nếu cần.
      }
    }

    // Update status
    booking.status = "confirmed";
    booking.payment_status = "paid";

    booking.payments.push({
      gateway: paymentInfo.gateway,
      gateway_transaction_id: paymentInfo.gateway_transaction_id,
      amount: booking.pricing.final_price,
      status: "succeeded",
    });

    await booking.save();
    console.log(
      `✅ Booking ${booking._id} confirmed & paid. Revenue held in escrow.`,
    );
    // Gửi email sau khi đã confirmed
    const toEmail = booking.customer_details?.email;
    if (toEmail) {
      // không block webhook: gửi async
      setImmediate(() => {
        sendPaymentSuccessEmail({
          to: toEmail,
          booking,
          paymentInfo,
        }).catch((err) =>
          console.error("Send payment email failed:", err.message),
        );
      });
    }

    return booking;
  }

  async cancelBooking(bookingId, userId, userAuthToken) {
    const booking = await Booking.findOne({ _id: bookingId, user_id: userId });
    if (!booking) throw new Error("Booking not found or access denied");
    return this._processCancellation(booking, userAuthToken);
  }

  async adminCancelBooking(bookingId, adminAuthToken) {
    const booking = await Booking.findById(bookingId);
    if (!booking) throw new Error("Booking not found");
    return this._processCancellation(booking, adminAuthToken);
  }

  // Helper for cancellation logic
  async _processCancellation(booking, authToken) {
    const originalStatus = booking.status;
    if (originalStatus === "cancelled")
      throw new Error("Booking is already cancelled");

    // chỉ để check "Thanh toán"
    const wasPaid = booking.payment_status === "paid";

    if (originalStatus === "pending") {
      booking.status = "cancelled";
      await booking.save();

      // (tuỳ bạn) pending/unpaid có gửi mail hay không
      return booking;
    }

    if (originalStatus === "confirmed") {
      // Release Stock (giữ nguyên)
      const releaseRequest = {
        items: booking.items.map((item) => ({
          inventoryId: item.inventory_id.toString(),
          quantity: item.quantity,
        })),
      };

      try {
        await axios.post(`${INVENTORY_URL}/inventory/release`, releaseRequest, {
          headers: { Authorization: authToken },
        });
      } catch (error) {
        console.error(`Stock release failed: ${error.message}`);
      }

      // Refund Money (không block hủy nếu refund lỗi)
      let refundRequestOk = false;

      try {
        await axios.post(
          `${PAYMENT_URL}/payment/refund`,
          { bookingId: booking._id.toString() },
          { headers: { "x-api-key": API_KEY } },
        );
        refundRequestOk = true;
      } catch (error) {
        // log chi tiết để debug payment-service
        const detail =
          error.response?.data?.message ||
          (typeof error.response?.data === "string"
            ? error.response.data
            : JSON.stringify(error.response?.data || {}));

        console.error(
          "Refund request failed:",
          error.response?.status,
          detail || error.message,
        );

        // ❗ không throw nữa -> vẫn cho hủy & gửi mail
      }

      // luôn cancel
      booking.status = "cancelled";
      await booking.save();

      // gửi mail nếu đã paid (dù refundRequestOk true/false thì mail vẫn nói “sau ít phút”)
      const toEmail = booking.customer_details?.email;
      if (wasPaid && toEmail) {
        setImmediate(() => {
          sendPaidCancellationEmail({ to: toEmail, booking }).catch((err) =>
            console.error("Send cancellation email failed:", err.message),
          );
        });
      }

      return booking;
    }

    // ✅ tránh return undefined
    throw new Error(`Cannot cancel booking when status is ${originalStatus}`);
  }

  async getAllBookings(queryParams) {
    const { page = 1, limit = 10, status, userId } = queryParams;
    let filter = {};
    if (status) filter.status = status;
    if (userId) filter.user_id = userId;
    const skip = (page - 1) * limit;
    const bookings = await Booking.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));
    const totalBookings = await Booking.countDocuments(filter);
    return {
      bookings,
      currentPage: parseInt(page),
      totalPages: Math.ceil(totalBookings / limit),
      totalBookings,
    };
  }

  async getPartnerBookings(partnerId, userToken, queryParams) {
    try {
      const catalogRes = await axios.get(
        `${CATALOG_URL}/products/partner/me?limit=200`,
        {
          headers: { Authorization: userToken },
        },
      );
      const data = catalogRes.data;
      const myProducts = Array.isArray(data) ? data : data.data || [];

      if (myProducts.length === 0) return { bookings: [], total: 0 };

      const myProductIds = myProducts.map((p) => p._id);
      const { page = 1, limit = 10, status } = queryParams;
      const filter = { "items.product_id": { $in: myProductIds } };

      if (status && status !== "ALL") filter.status = status.toLowerCase();

      const skip = (page - 1) * limit;
      const bookings = await Booking.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit));
      const total = await Booking.countDocuments(filter);

      return {
        bookings,
        total,
        currentPage: parseInt(page),
        totalPages: Math.ceil(total / limit),
      };
    } catch (error) {
      console.error("Error fetching partner bookings:", error.message);
      return { bookings: [], total: 0 };
    }
  }

  async getPartnerBookingDetail(bookingId) {
    const booking = await Booking.findById(bookingId);
    if (!booking) throw new Error("Booking not found");
    return booking;
  }
}

module.exports = new BookingService();
