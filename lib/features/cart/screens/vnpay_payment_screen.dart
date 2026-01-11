// [current_directory]/vnpay_payment_screen.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VnpayPaymentScreen extends StatefulWidget {
  final String vnpayUrl;
  
  // ReturnUrlHost phải khớp với returnUrl trong server.js ('http://localhost:8080/vnpay_return')
  final String returnUrlHost = 'localhost:8080'; 

  const VnpayPaymentScreen({super.key, required this.vnpayUrl});

  @override
  State<VnpayPaymentScreen> createState() => _VnpayPaymentScreenState();
}

class _VnpayPaymentScreenState extends State<VnpayPaymentScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.parse(request.url);

            // 1. Kiểm tra ReturnUrl (URL mà VNPAY gọi về sau khi thanh toán)
            if (uri.host.contains('localhost') && uri.port == 8080) {
              
              String responseCode = uri.queryParameters['vnp_ResponseCode'] ?? 'N/A';
              
              if (responseCode == '00') {
                  // Thành công -> Trả về true để CheckoutScreen hiện dialog
                  Navigator.pop(context, true);
              } else {
                  // Thất bại -> Trả về false (hoặc thông báo)
                  Navigator.pop(context, false);
                  
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Thanh toán thất bại (Mã lỗi: $responseCode)')),
                    );
                  });
              }
              
              return NavigationDecision.prevent; // Ngăn chặn điều hướng tiếp
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.vnpayUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cổng Thanh Toán VNPAY'),
        backgroundColor: Colors.indigo.shade800,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}