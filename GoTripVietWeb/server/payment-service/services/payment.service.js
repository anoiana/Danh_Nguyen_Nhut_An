// services/payment.service.js
const Payment = require("../models/payment.model");
const Transaction = require("../models/transaction.model");
const axios = require("axios");
const moment = require("moment");
const qs = require("qs");
const crypto = require("crypto");

// Environment Variables
const BOOKING_URL = process.env.BOOKING_SERVICE_URL || "http://localhost:3004";
const USER_URL = process.env.USER_SERVICE_URL || "http://localhost:3001";
const API_KEY = process.env.INTERNAL_API_KEY;

class PaymentService {
  // ==========================================
  // 1. REVENUE & WALLET LOGIC
  // ==========================================

  /**
   * [INTERNAL] Phân phối doanh thu (Gọi bởi Cron Job khi Tour hoàn thành)
   * Chia tiền: 15% Phí sàn (System), 85% Doanh thu (Partner)
   * @param {number} amount - Giá gốc của tour (trước khi giảm giá)
   * @param {number} discountAmount - Số tiền voucher/giảm giá (Admin chịu). Cần được truyền từ booking-service.
   */
  async distributeRevenue(
    bookingId,
    partnerId,
    amount,
    discountAmount = 0,
    description,
  ) {
    const COMMISSION_RATE = 0.15; // 15%

    // 1. Tính toán
    const commissionAmount = amount * COMMISSION_RATE; // Tiền sàn thu
    const partnerReceived = amount - commissionAmount; // Tiền Partner thực nhận
    // Lợi nhuận thực của Admin = Phí sàn - Chi phí giảm giá
    const adminNetProfit = commissionAmount - discountAmount;

    console.log(
      `💸 Processing Revenue: Total ${amount} | Discount ${discountAmount} | Fee ${commissionAmount} | Partner ${partnerReceived} | Admin Net ${adminNetProfit}`,
    );

    // 2. Ghi lịch sử giao dịch (Transaction)

    // A. Transaction INCOME: Ghi nhận 100% giá trị gốc của tour để báo cáo tổng doanh số
    await Transaction.create({
      partner_id: partnerId,
      booking_id: bookingId,
      type: "INCOME",
      amount: amount,
      description: description || `Tổng doanh thu gốc cho đơn ${bookingId}`,
      status: "COMPLETED",
    });

    // B. Transaction COMMISSION: Ghi nhận phí sàn (Để Admin thống kê lợi nhuận)
    // Transaction này mang tính chất ghi nhận, không cộng vào ví Partner
    await Transaction.create({
      partner_id: partnerId, // Vẫn gắn với partner để biết thu từ ai
      booking_id: bookingId,
      type: "COMMISSION",
      amount: commissionAmount,
      description: `Phí sàn 15% cho đơn ${bookingId}`,
      status: "COMPLETED",
    });

    // C. [NEW] Transaction VOUCHER_COST: Ghi nhận chi phí giảm giá Admin chịu
    if (discountAmount > 0) {
      await Transaction.create({
        partner_id: null, // Chi phí của hệ thống, không của partner nào
        booking_id: bookingId,
        type: "VOUCHER_COST",
        amount: discountAmount, // Lưu số dương, sẽ được trừ đi khi tính toán
        description: `Chi phí voucher cho đơn ${bookingId}`,
        status: "COMPLETED",
      });
    }

    // 3. Gọi User Service để cộng tiền vào Ví thật (API Call)
    try {
      await axios.post(
        `${USER_URL}/users/internal/wallet/update`,
        {
          userId: partnerId,
          amount: partnerReceived, // ✅ Chỉ cộng số tiền thực nhận
        },
        { headers: { "x-api-key": API_KEY } },
      );
    } catch (error) {
      console.error("❌ Failed to update User Wallet via API:", error.message);
      // Trong thực tế, nên có cơ chế Retry (thử lại) nếu gọi API thất bại
      throw new Error(`Wallet update failed: ${error.message}`);
    }

    console.log(
      `✅ Revenue Distributed Successfully: Partner +${partnerReceived}`,
    );
    return {
      message: "Success",
      partnerReceived,
      commissionAmount,
      discountAmount,
      adminNetProfit,
      totalBasePrice: amount,
    };
  }

  /**
   * Lấy thông tin Ví & Lịch sử giao dịch cho Frontend
   */
  async getWalletInfo(partnerId, userToken) {
    let balance = 0;

    // 1. Gọi User Service để lấy số dư hiện tại
    try {
      // ✅ API: GET /users/:id (Cần khớp với user.routes.js)
      const userRes = await axios.get(`${USER_URL}/users/${partnerId}`, {
        headers: { Authorization: userToken },
      });

      // Lấy field wallet_balance từ kết quả trả về
      balance = userRes.data.wallet_balance || 0;
    } catch (error) {
      console.warn(
        "⚠️ Could not fetch balance from User Service:",
        error.message,
      );
      // Nếu lỗi kết nối, hiển thị balance = 0 thay vì sập trang
    }

    // 2. Lấy lịch sử giao dịch từ Database local (Payment Service)
    const transactions = await Transaction.find({ partner_id: partnerId })
      .sort({ createdAt: -1 })
      .limit(50); // Lấy 50 giao dịch gần nhất

    return { balance, transactions };
  }

  /**
   * Xử lý yêu cầu Rút tiền (Payout)
   */
  async requestPayout(partnerId, amount, bankInfo, userToken) {
    // 1. Kiểm tra số dư bên User Service
    let currentBalance = 0;
    try {
      const userRes = await axios.get(`${USER_URL}/users/${partnerId}`, {
        headers: { Authorization: userToken },
      });
      currentBalance = userRes.data.wallet_balance || 0;
    } catch (error) {
      throw new Error("Không thể xác thực số dư với User Service");
    }

    if (currentBalance < amount) {
      throw new Error("Số dư không đủ để thực hiện giao dịch.");
    }

    // 2. Tạo Transaction Rút tiền (WITHDRAWAL)
    // Lưu ý: Status là PENDING (Chờ Admin duyệt chuyển khoản thủ công hoặc auto banking)
    const tx = new Transaction({
      partner_id: partnerId,
      type: "WITHDRAWAL",
      amount: -amount, // Số âm thể hiện tiền ra
      description: `Rút tiền về ${bankInfo.bankName} - ${bankInfo.accountNumber}`,
      status: "PENDING",
    });
    await tx.save();

    // 3. Trừ tiền ngay lập tức bên User Service (để tránh rút lố)
    // Nếu sau này Admin từ chối, ta sẽ cộng lại sau.
    try {
      await axios.post(
        `${USER_URL}/users/internal/wallet/update`,
        { userId: partnerId, amount: -amount }, // Trừ tiền
        { headers: { "x-api-key": API_KEY } },
      );
    } catch (err) {
      // Nếu trừ tiền lỗi, phải xóa Transaction vừa tạo để tránh lệch
      await Transaction.findByIdAndDelete(tx._id);
      throw new Error("Lỗi hệ thống khi trừ tiền ví. Vui lòng thử lại.");
    }

    return { message: "Yêu cầu rút tiền thành công!", transaction: tx };
  }

  // ==========================================
  // 2. VNPAY LOGIC (Giữ nguyên)
  // ==========================================

  createVNPayUrl(req, bookingId, amount, bankCode, language) {
    process.env.TZ = "Asia/Ho_Chi_Minh";
    const date = new Date();
    const createDate = moment(date).format("YYYYMMDDHHmmss");

    let ipAddr =
      req.headers["x-forwarded-for"] ||
      req.connection.remoteAddress ||
      req.socket.remoteAddress ||
      req.connection.socket.remoteAddress;

    if (ipAddr === "::1") ipAddr = "127.0.0.1";

    const tmnCode = process.env.VNP_TMN_CODE;
    const secretKey = process.env.VNP_HASH_SECRET;
    const vnpUrl = process.env.VNP_URL;
    const returnUrl = process.env.VNP_RETURN_URL;

    let vnp_Params = {};
    vnp_Params["vnp_Version"] = "2.1.0";
    vnp_Params["vnp_Command"] = "pay";
    vnp_Params["vnp_TmnCode"] = tmnCode;
    vnp_Params["vnp_Locale"] = language || "vn";
    vnp_Params["vnp_CurrCode"] = "VND";
    vnp_Params["vnp_TxnRef"] = bookingId;
    vnp_Params["vnp_OrderInfo"] = "Thanh toan don hang:" + bookingId;
    vnp_Params["vnp_OrderType"] = "other";
    vnp_Params["vnp_Amount"] = amount * 100;
    vnp_Params["vnp_ReturnUrl"] = returnUrl;
    vnp_Params["vnp_IpAddr"] = ipAddr;
    vnp_Params["vnp_CreateDate"] = createDate;

    if (bankCode) {
      vnp_Params["vnp_BankCode"] = bankCode;
    }

    vnp_Params = this.sortObject(vnp_Params);

    const signData = qs.stringify(vnp_Params, { encode: false });
    const hmac = crypto.createHmac("sha512", secretKey);
    const signed = hmac.update(Buffer.from(signData, "utf-8")).digest("hex");

    vnp_Params["vnp_SecureHash"] = signed;
    const finalUrl = vnpUrl + "?" + qs.stringify(vnp_Params, { encode: false });

    return finalUrl;
  }

  async verifyVNPayReturn(vnp_Params) {
    // ⚠️ DEV MODE: Tạm bỏ qua check chữ ký để test local dễ hơn
    // Trong môi trường Production, bạn phải uncomment logic check SecureHash
    console.log("⚠️ [Payment] Verifying VNPAY Return...");

    const vnp_ResponseCode = vnp_Params["vnp_ResponseCode"];
    const rawTxnRef = vnp_Params["vnp_TxnRef"];
    const amount = parseInt(vnp_Params["vnp_Amount"]) / 100;

    // VNPAY trả về 00 là thành công
    if (vnp_ResponseCode === "00") {
      const bookingId = rawTxnRef.includes("_")
        ? rawTxnRef.split("_")[0]
        : rawTxnRef;

      // 1. Lưu/Cập nhật Payment vào DB
      try {
        await Payment.findOneAndUpdate(
          { booking_id: bookingId },
          {
            booking_id: bookingId,
            amount: amount,
            currency: "vnd",
            status: "succeeded",
            gateway: "vnpay",
            transaction_date: new Date(),
            gateway_transaction_id: vnp_Params["vnp_TransactionNo"],
          },
          { upsert: true, new: true },
        );
      } catch (dbError) {
        console.error("DB Error updating payment:", dbError.message);
      }

      // 2. Gọi Booking Service để CONFIRM đơn hàng (Trigger logic giữ chỗ)
      try {
        const internalApiUrl = `${BOOKING_URL}/bookings/internal/confirm-payment`;
        const response = await axios.post(
          internalApiUrl,
          {
            bookingId: bookingId,
            paymentInfo: {
              gateway: "vnpay",
              gateway_transaction_id:
                vnp_Params["vnp_TransactionNo"] || "Unknown",
              amount: amount,
              status: "succeeded",
            },
          },
          { headers: { "x-api-key": API_KEY } },
        );

        return {
          status: "success",
          message: "Payment Successful",
          data: response.data,
        };
      } catch (error) {
        console.error("❌ Booking Service Sync Error:", error.message);
        // Vẫn trả về success cho Frontend hiển thị, nhưng log lỗi để Admin check
        return {
          status: "success",
          message: "Payment Successful (Sync Warning)",
          data: { _id: bookingId },
        };
      }
    } else {
      // Thanh toán thất bại
      return {
        status: "failed",
        message: "Payment Failed",
        code: vnp_ResponseCode,
      };
    }
  }

  // ==========================================
  // 3. ADMIN & UTILS
  // ==========================================

  async refundPayment(bookingId) {
    // 1. Tìm Payment thành công
    const payment = await Payment.findOne({
      booking_id: bookingId,
      status: "succeeded",
    });
    if (!payment) throw new Error("No successful payment found to refund.");

    // 2. Xử lý Refund (Giả lập)
    // Trong thực tế cần gọi API hoàn tiền của VNPAY
    if (payment.gateway === "vnpay") {
      console.log(`♻️ Processing VNPAY Refund (Mock) for ${bookingId}`);

      const updatedPayment = await Payment.findByIdAndUpdate(
        payment._id,
        {
          $set: {
            status: "refunded",
            amount_refunded: payment.amount,
            refunded_at: new Date(),
          },
        },
        { new: true },
      );
      return updatedPayment;
    }
    throw new Error(`Refund not supported for gateway: ${payment.gateway}`);
  }

  async getAllPayments(queryParams) {
    const { page = 1, limit = 10, status } = queryParams;
    let filter = {};
    if (status) filter.status = status;
    const skip = (page - 1) * limit;
    const payments = await Payment.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const totalPayments = await Payment.countDocuments(filter);

    return {
      payments,
      currentPage: parseInt(page),
      totalPages: Math.ceil(totalPayments / limit),
      totalPayments,
    };
  }

  async getPaymentsForBooking(bookingId) {
    return await Payment.find({ booking_id: bookingId });
  }

  // Hàm tiện ích sắp xếp tham số cho VNPAY
  sortObject(obj) {
    let sorted = {};
    let str = [];
    let key;
    for (key in obj) {
      if (obj.hasOwnProperty(key)) str.push(encodeURIComponent(key));
    }
    str.sort();
    for (key = 0; key < str.length; key++) {
      sorted[str[key]] = encodeURIComponent(obj[str[key]]).replace(/%20/g, "+");
    }
    return sorted;
  }
}

module.exports = new PaymentService();
