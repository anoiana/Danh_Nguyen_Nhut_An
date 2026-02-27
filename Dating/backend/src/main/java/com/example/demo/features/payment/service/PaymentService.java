package com.example.demo.features.payment.service;

import com.example.demo.features.payment.config.VNPayConfig;
import com.example.demo.features.payment.entity.PaymentTransaction;
import com.example.demo.features.payment.repository.PaymentTransactionRepository;
import com.example.demo.features.scheduling.entity.DateBooking;
import com.example.demo.features.scheduling.repository.DateBookingRepository;
import com.example.demo.features.scheduling.service.DateBookingService;
import com.example.demo.features.user.entity.User;
import com.example.demo.features.user.repository.UserRepository;

import com.example.demo.infra.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.ZonedDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * Service to handle VNPay logic: generating URLs and processing IPNs.
 */
@Service
@RequiredArgsConstructor
public class PaymentService {

    private final VNPayConfig vnPayConfig;
    private final PaymentTransactionRepository paymentRepo;
    private final DateBookingRepository dateBookingRepo;
    private final UserRepository userRepo;
    private final DateBookingService dateBookingService;

    @Transactional
    public String createPaymentUrl(Long bookingId, Long userId, Long amount, HttpServletRequest request) {
        DateBooking booking = dateBookingRepo.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Booking not found: " + bookingId));
        User user = userRepo.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

        // Create transaction record
        String txnRef = "VNP" + System.currentTimeMillis(); // Mã bắt đầu bằng VNP
        PaymentTransaction txn = new PaymentTransaction();
        txn.setBooking(booking);
        txn.setUser(user);
        txn.setAmount(amount);
        txn.setTxnRef(txnRef);
        txn.setStatus("PENDING");
        paymentRepo.save(txn);

        // Build VNPay params
        Map<String, String> vnp_Params = new HashMap<>();
        vnp_Params.put("vnp_Version", "2.1.0");
        vnp_Params.put("vnp_Command", "pay");
        vnp_Params.put("vnp_TmnCode", vnPayConfig.getVnpTmnCode());
        vnp_Params.put("vnp_Amount", String.valueOf(amount * 100)); // VNPay amount is multiplied by 100
        vnp_Params.put("vnp_CurrCode", "VND");
        vnp_Params.put("vnp_TxnRef", txnRef);
        vnp_Params.put("vnp_OrderInfo", "Thanh toan lich hen DatingApp: " + txnRef);
        vnp_Params.put("vnp_OrderType", "other");
        vnp_Params.put("vnp_Locale", "vn");
        vnp_Params.put("vnp_ReturnUrl", vnPayConfig.getVnpReturnUrl() + "?bookingId=" + bookingId);

        String ipAddr = request.getHeader("X-Forwarded-For");
        if (ipAddr == null || ipAddr.isEmpty()) {
            ipAddr = request.getRemoteAddr();
        }
        vnp_Params.put("vnp_IpAddr", ipAddr);

        // Lấy thời gian hiện tại theo múi giờ Việt Nam
        ZonedDateTime now = ZonedDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh"));
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");
        String vnp_CreateDate = now.format(formatter);
        vnp_Params.put("vnp_CreateDate", vnp_CreateDate);

        // Bỏ vnp_ExpireDate để VNPay tự tính (hoặc dùng mặc định 15p) cho an toàn
        // vnp_Params.put("vnp_ExpireDate", now.plusMinutes(15).format(formatter));

        // Sort and build query
        List<String> fieldNames = new ArrayList<>(vnp_Params.keySet());
        Collections.sort(fieldNames);

        StringBuilder hashData = new StringBuilder();
        StringBuilder query = new StringBuilder();

        // Theo chuẩn VNPay 2.1.0: hashData VÀ query đều phải URL-encode
        for (String fieldName : fieldNames) {
            String fieldValue = vnp_Params.get(fieldName);
            if (fieldValue != null && !fieldValue.isEmpty()) {
                try {
                    String encodedName = URLEncoder.encode(fieldName, StandardCharsets.US_ASCII.toString());
                    String encodedValue = URLEncoder.encode(fieldValue, StandardCharsets.US_ASCII.toString());

                    // hashData và query string là GIỐNG NHAU (đều encode)
                    if (hashData.length() > 0) {
                        hashData.append('&');
                        query.append('&');
                    }
                    hashData.append(encodedName).append('=').append(encodedValue);
                    query.append(encodedName).append('=').append(encodedValue);
                } catch (Exception e) {
                }
            }
        }

        String queryUrl = query.toString();
        String vnp_SecureHash = VNPayConfig.hmacSHA512(vnPayConfig.getVnpHashSecret(), hashData.toString());
        queryUrl += "&vnp_SecureHash=" + vnp_SecureHash;

        return vnPayConfig.getVnpUrl() + "?" + queryUrl;
    }

    @Transactional
    public String processIpn(Map<String, String> params) {
        String secureHash = params.get("vnp_SecureHash");
        params.remove("vnp_SecureHashType");
        params.remove("vnp_SecureHash");
        params.remove("bookingId"); // Remove non-VNPay param before verification

        // Hash data again — phải URL-encode giống lúc tạo URL
        List<String> fieldNames = new ArrayList<>(params.keySet());
        Collections.sort(fieldNames);
        StringBuilder hashData = new StringBuilder();
        for (String fieldName : fieldNames) {
            String fieldValue = params.get(fieldName);
            if (fieldValue != null && !fieldValue.isEmpty()) {
                try {
                    String encodedName = URLEncoder.encode(fieldName, StandardCharsets.US_ASCII.toString());
                    String encodedValue = URLEncoder.encode(fieldValue, StandardCharsets.US_ASCII.toString());
                    if (hashData.length() > 0)
                        hashData.append('&');
                    hashData.append(encodedName).append('=').append(encodedValue);
                } catch (Exception e) {
                }
            }
        }

        String calculatedHash = VNPayConfig.hmacSHA512(vnPayConfig.getVnpHashSecret(), hashData.toString());
        if (!calculatedHash.equals(secureHash)) {
            return "INVALID_SIGNATURE";
        }

        String txnRef = params.get("vnp_TxnRef");
        String responseCode = params.get("vnp_ResponseCode");

        PaymentTransaction txn = paymentRepo.findByTxnRef(txnRef).orElse(null);
        if (txn == null) {
            return "ORDER_NOT_FOUND";
        }

        if (!"PENDING".equals(txn.getStatus())) {
            return "ALREADY_PROCESSED";
        }

        if ("00".equals(responseCode)) {
            txn.setStatus("SUCCESS");
            paymentRepo.save(txn);

            // Integrate with DateBookingService:
            // Since this user paid successfully, call confirmBooking logic
            dateBookingService.confirmBooking(txn.getBooking().getId(), txn.getUser().getId());
        } else {
            txn.setStatus("FAILED");
            paymentRepo.save(txn);
        }

        return "SUCCESS";
    }
}
