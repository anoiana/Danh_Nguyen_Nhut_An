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
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
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
    public String createPaymentUrl(Long bookingId, Long userId, Long amount) {
        DateBooking booking = dateBookingRepo.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Booking not found: " + bookingId));
        User user = userRepo.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

        // Create transaction record
        String txnRef = VNPayConfig.getRandomNumber(8);
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
        vnp_Params.put("vnp_IpAddr", "127.0.0.1"); // Dummy IP for local

        Calendar cld = Calendar.getInstance(TimeZone.getTimeZone("Etc/GMT+7"));
        SimpleDateFormat formatter = new SimpleDateFormat("yyyyMMddHHmmss");
        String vnp_CreateDate = formatter.format(cld.getTime());
        vnp_Params.put("vnp_CreateDate", vnp_CreateDate);

        cld.add(Calendar.MINUTE, 15);
        String vnp_ExpireDate = formatter.format(cld.getTime());
        vnp_Params.put("vnp_ExpireDate", vnp_ExpireDate);

        // Sort and build query
        List<String> fieldNames = new ArrayList<>(vnp_Params.keySet());
        Collections.sort(fieldNames);
        StringBuilder hashData = new StringBuilder();
        StringBuilder query = new StringBuilder();
        Iterator<String> itr = fieldNames.iterator();

        while (itr.hasNext()) {
            String fieldName = itr.next();
            String fieldValue = vnp_Params.get(fieldName);
            if ((fieldValue != null) && (fieldValue.length() > 0)) {
                try {
                    hashData.append(fieldName).append('=')
                            .append(URLEncoder.encode(fieldValue, StandardCharsets.US_ASCII.toString()));
                    query.append(URLEncoder.encode(fieldName, StandardCharsets.US_ASCII.toString()))
                            .append('=').append(URLEncoder.encode(fieldValue, StandardCharsets.US_ASCII.toString()));
                    if (itr.hasNext()) {
                        query.append('&');
                        hashData.append('&');
                    }
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

        // Hash data again
        List<String> fieldNames = new ArrayList<>(params.keySet());
        Collections.sort(fieldNames);
        StringBuilder hashData = new StringBuilder();
        Iterator<String> itr = fieldNames.iterator();
        while (itr.hasNext()) {
            String fieldName = itr.next();
            String fieldValue = params.get(fieldName);
            if ((fieldValue != null) && (fieldValue.length() > 0)) {
                try {
                    hashData.append(fieldName).append('=')
                            .append(URLEncoder.encode(fieldValue, StandardCharsets.US_ASCII.toString()));
                    if (itr.hasNext()) {
                        hashData.append('&');
                    }
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
