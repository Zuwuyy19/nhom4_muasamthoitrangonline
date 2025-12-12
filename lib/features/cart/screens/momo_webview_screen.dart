import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'payment_confirmation_screen.dart';

class MomoWebviewScreen extends StatefulWidget {
  final int totalAmount;
  final String customerName;
  final String phoneNumber;
  final String paymentUrl; // URL returned from MoMo API

  const MomoWebviewScreen({
    super.key,
    required this.totalAmount,
    required this.customerName,
    required this.phoneNumber,
    required this.paymentUrl,
  });

  @override
  State<MomoWebviewScreen> createState() => _MomoWebviewScreenState();
}

class _MomoWebviewScreenState extends State<MomoWebviewScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi tải trang: ${error.description}')),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _webViewController.canGoBack()) {
          await _webViewController.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thanh toán MoMo'),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _webViewController),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.pink),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.pink,
          onPressed: _showPaymentCompleteDialog,
          tooltip: 'Xác nhận thanh toán',
          child: const Icon(Icons.check),
        ),
      ),
    );
  }

  void _showPaymentCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: const Text('Bạn đã hoàn thành thanh toán?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completePayment();
            },
            child: const Text('Có'),
          ),
        ],
      ),
    );
  }

  void _completePayment() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentConfirmationScreen(
          totalAmount: widget.totalAmount,
          customerName: widget.customerName,
          phoneNumber: widget.phoneNumber,
          paymentMethod: 'MoMo',
        ),
      ),
    );
  }
}
