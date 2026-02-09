import 'package:flutter/material.dart';
import 'package:mobile/features/payment/view_models/payment_view_model.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'payment_success_screen.dart'; // Import the new screen

class PaymentWebView extends StatefulWidget {
  final String paymentUrl;
  final String bookingId; // Add bookingId to pass to success screen

  const PaymentWebView({
    Key? key,
    required this.paymentUrl,
    required this.bookingId, // Add this
  }) : super(key: key);

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
            _handleRedirect(url); // Check URL here
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          // Even if the page fails to load (because localhost doesn't exist on phone),
          // we can still catch the URL in 'onWebResourceError' or 'onNavigationRequest'
          // but usually onPageStarted is enough for redirects.
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handleRedirect(String url) async {
    if (url.contains('booking-success') || url.contains('vnp_ResponseCode')) {
      // Dừng load trang để tránh lỗi localhost
      _controller.loadRequest(Uri.parse('about:blank'));

      final uri = Uri.parse(url);
      final responseCode = uri.queryParameters['vnp_ResponseCode'];

      if (responseCode == '00') {
        // ✅ SỬA LỖI: Gọi API báo Backend update DB trước!
        // Hiển thị loading dialog nếu cần
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator()),
        );

        final viewModel = Provider.of<PaymentViewModel>(context, listen: false);
        final isConfirmed = await viewModel.confirmPaymentSuccess(url);

        // Tắt loading dialog
        Navigator.pop(context);

        if (isConfirmed) {
          // Backend đã update DB -> Giờ mới chuyển màn hình
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentSuccessScreen(bookingId: widget.bookingId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Lỗi xác thực thanh toán với máy chủ."),
            ),
          );
          Navigator.pop(context); // Quay lại
        }
      } else {
        // Thất bại
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Thanh toán bị hủy hoặc lỗi.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán VNPAY"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.teal)),
        ],
      ),
    );
  }
}
