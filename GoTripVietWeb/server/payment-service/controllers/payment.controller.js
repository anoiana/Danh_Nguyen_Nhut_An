// controllers/payment.controller.js
const paymentService = require("../services/payment.service");
const Transaction = require("../models/transaction.model");

class PaymentController {
  // ==========================================
  // 1. VNPAY PAYMENT
  // ==========================================

  // POST /payment/create-vnpay-url
  async createVNPayUrl(req, res) {
    try {
      const { amount, bookingId, bankCode, language } = req.body;

      if (!bookingId || !amount) {
        return res.status(400).json({ message: "Missing bookingId or amount" });
      }

      // Call Service to generate URL
      const paymentUrl = paymentService.createVNPayUrl(
        req,
        bookingId,
        amount,
        bankCode,
        language,
      );

      // Return URL to Frontend
      res.status(200).json({ paymentUrl });
    } catch (error) {
      console.error("VNPAY URL Error:", error);
      res
        .status(500)
        .json({ message: "Error creating VNPAY link", error: error.message });
    }
  }

  // GET /payment/vnpay-return
  async vnpayReturn(req, res) {
    try {
      // req.query contains all VNPAY parameters
      const result = await paymentService.verifyVNPayReturn(req.query);

      if (result.status === "success") {
        res.status(200).json(result);
      } else {
        res.status(400).json(result);
      }
    } catch (error) {
      res.status(500).json({
        status: "error",
        message: "Server error",
        error: error.message,
      });
    }
  }

  // ==========================================
  // 2. PARTNER WALLET (NEW)
  // ==========================================

  // GET /payment/wallet/me
  async getMyWallet(req, res) {
    try {
      const partnerId = req.user.id;
      // Get Token to authenticate with User Service
      const userToken = req.headers["authorization"];

      const data = await paymentService.getWalletInfo(partnerId, userToken);
      res.status(200).json(data);
    } catch (error) {
      console.error("Get Wallet Error:", error.message);
      res.status(500).json({ message: error.message });
    }
  }

  // POST /payment/payout-request
  async requestPayout(req, res) {
    try {
      const partnerId = req.user.id;
      const { amount, bankInfo } = req.body;
      const userToken = req.headers["authorization"];

      const result = await paymentService.requestPayout(
        partnerId,
        amount,
        bankInfo,
        userToken,
      );
      res.status(200).json(result);
    } catch (error) {
      console.error("Payout Request Error:", error.message);
      res.status(400).json({ message: error.message });
    }
  }

  // ==========================================
  // 3. INTERNAL (SERVICE-TO-SERVICE)
  // ==========================================

  // POST /payment/internal/distribute-revenue
  // Called by Booking Service (Cron Job)
  async distributeRevenue(req, res) {
    try {
      const { bookingId, partnerId, amount, discountAmount, description } =
        req.body;

      const result = await paymentService.distributeRevenue(
        bookingId,
        partnerId,
        amount,
        discountAmount || 0,
        description,
      );
      res.status(200).json(result);
    } catch (error) {
      console.error("Distribute Revenue Error:", error.message);
      res.status(500).json({ message: error.message });
    }
  }

  // POST /payment/refund
  async refundPayment(req, res) {
    try {
      const { bookingId } = req.body;
      if (!bookingId)
        return res.status(400).json({ message: "bookingId is required" });

      const payment = await paymentService.refundPayment(bookingId);
      return res.status(200).json(payment);
    } catch (error) {
      // nếu là lỗi nghiệp vụ "không có payment succeeded" -> 404
      const msg = error.message || "Refund failed";
      const isNotFound = msg.includes("No successful payment found");
      return res.status(isNotFound ? 404 : 400).json({ message: msg });
    }
  }

  // ==========================================
  // 4. ADMIN API
  // ==========================================

  // GET /payment/admin/all
  async adminGetAllPayments(req, res) {
    try {
      const result = await paymentService.getAllPayments(req.query);
      res.status(200).json(result);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }

  // GET /payment/booking/:bookingId
  async adminGetPaymentsForBooking(req, res) {
    try {
      const payments = await paymentService.getPaymentsForBooking(
        req.params.bookingId,
      );
      res.status(200).json(payments);
    } catch (error) {
      res
        .status(404)
        .json({ message: "Payments not found", error: error.message });
    }
  }

  async getSystemStats(req, res) {
    try {
      // Lấy tất cả giao dịch đã hoàn thành
      const transactions = await Transaction.find({ status: "COMPLETED" }).sort(
        { createdAt: -1 },
      );

      let totalVolume = 0; // Tổng doanh số (GMV) từ các đơn hàng, tính trên giá gốc.
      let adminGrossProfit = 0; // Lợi nhuận gộp của Admin (phí sàn 15%).
      let totalVoucherCost = 0; // Tổng chi phí voucher Admin chịu.

      transactions.forEach((t) => {
        const val = t.amount;

        if (t.type === "INCOME") {
          // INCOME là 100% giá trị gốc của tour
          totalVolume += val;
        } else if (t.type === "COMMISSION") {
          // COMMISSION là 15% phí sàn
          adminGrossProfit += val;
        } else if (t.type === "VOUCHER_COST") {
          // VOUCHER_COST là chi phí admin chịu
          totalVoucherCost += val;
        }
      });

      // Lợi nhuận ròng của Admin = Phí sàn - Chi phí voucher
      const adminNetProfit = adminGrossProfit - totalVoucherCost;

      // Tiền Partner nhận = Tổng giá trị tour - Phí sàn
      const partnerPayout = totalVolume - adminGrossProfit;

      res.status(200).json({
        stats: {
          totalVolume: totalVolume, // Tổng doanh số (giá gốc)
          adminProfit: adminNetProfit, // Lợi nhuận RÒNG của Admin
          partnerPayout: partnerPayout, // Tổng tiền Partner được hưởng
          // Thêm 2 field mới để minh bạch hơn trên dashboard
          adminGrossProfit: adminGrossProfit,
          totalVoucherCost: totalVoucherCost,
          transactionCount: transactions.length,
        },
        transactions,
      });
    } catch (error) {
      console.error("Stats Error:", error);
      res.status(500).json({ message: error.message });
    }
  }
}

module.exports = new PaymentController();
