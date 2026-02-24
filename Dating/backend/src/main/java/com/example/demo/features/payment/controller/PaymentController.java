package com.example.demo.features.payment.controller;

import com.example.demo.features.payment.dto.PaymentUrlResponse;
import com.example.demo.features.payment.service.PaymentService;
import com.example.demo.infra.security.UserDetailsImpl;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Controller for VNPay integrations.
 */
@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final PaymentService paymentService;

    /**
     * Called by the frontend to get the VNPay redirect URL.
     */
    @GetMapping("/create-url")
    public ResponseEntity<PaymentUrlResponse> createPaymentUrl(
            @RequestParam Long bookingId,
            Authentication authentication) {

        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
        Long userId = userDetails.getId();

        // 100,000 VND fixed price for the date token
        String url = paymentService.createPaymentUrl(bookingId, userId, 100000L);
        return ResponseEntity.ok(new PaymentUrlResponse(url));
    }

    /**
     * Called by the frontend to confirm payment on return (fallback for localhost
     * IPN).
     */
    @GetMapping("/verify-payment")
    public ResponseEntity<Map<String, String>> verifyPayment(@RequestParam Map<String, String> params) {
        String result = paymentService.processIpn(params);
        return ResponseEntity.ok(Map.of("result", result));
    }

    /**
     * Webhook called securely by VNPay servers.
     * Note: This endpoint must be public (whitelisted in SecurityConfig).
     */
    @GetMapping("/vnpay-ipn")
    public ResponseEntity<Map<String, String>> vnpayIpn(@RequestParam Map<String, String> params) {
        String result = paymentService.processIpn(params);
        if ("SUCCESS".equals(result)) {
            return ResponseEntity.ok(Map.of("RspCode", "00", "Message", "Confirm Success"));
        } else if ("INVALID_SIGNATURE".equals(result)) {
            return ResponseEntity.ok(Map.of("RspCode", "97", "Message", "Invalid Signature"));
        } else {
            return ResponseEntity.ok(Map.of("RspCode", "02", "Message", "Order already confirmed"));
        }
    }
}
