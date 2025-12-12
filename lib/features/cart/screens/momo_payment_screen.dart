import 'package:flutter/material.dart';
import 'payment_confirmation_screen.dart';
import 'card_payment_screen.dart';
import 'momo_webview_screen.dart';
import 'package:nhom4_muasamthoitrangonline/common/constants/momo_api_service.dart';

class MomoPaymentScreen extends StatefulWidget {
  final int totalAmount;
  final String customerName;
  final String phoneNumber;

  const MomoPaymentScreen({
    super.key,
    required this.totalAmount,
    required this.customerName,
    required this.phoneNumber,
  });

  @override
  State<MomoPaymentScreen> createState() => _MomoPaymentScreenState();
}

class _MomoPaymentScreenState extends State<MomoPaymentScreen> {
  int _selectedPaymentMethod = 1; // 1: Tài khoản MoMo, 2: Thẻ
  bool _isProcessing = false;

  // Giả lập số dư tài khoản MoMo
  final int _momoBalance = 5000000; // 5 triệu đồng

  @override
  Widget build(BuildContext context) {
    final canAfford = _momoBalance >= widget.totalAmount;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Thanh toán MoMo", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SỐ DƯ MOMO ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/momo_logo.png',
                        width: 40,
                        height: 40,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "MoMo",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Số dư hiện tại",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${_momoBalance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- THÔNG TIN THANH TOÁN ---
            const Text(
              "Thông tin thanh toán",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
              ),
              child: Column(
                children: [
                  _buildInfoRow("Họ và tên", widget.customerName),
                  const Divider(height: 20),
                  _buildInfoRow("Số điện thoại", widget.phoneNumber),
                  const Divider(height: 20),
                  _buildInfoRow(
                    "Số tiền",
                    "${widget.totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ",
                    isAmount: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- PHƯƠNG THỨC THANH TOÁN ---
            const Text(
              "Chọn phương thức thanh toán",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildPaymentMethodOption(1, "Tài khoản MoMo", Icons.account_balance_wallet),
            const SizedBox(height: 10),
            _buildPaymentMethodOption(2, "Thẻ tín dụng / Thẻ ghi nợ", Icons.credit_card),
            const SizedBox(height: 10),

            // --- TÓM TẮT THANH TOÁN ---
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    "Số tiền",
                    widget.totalAmount,
                  ),
                  const SizedBox(height: 10),
                  _buildSummaryRow(
                    "Phí giao dịch",
                    0,
                  ),
                  const Divider(height: 20),
                  _buildSummaryRow(
                    "Tổng cộng",
                    widget.totalAmount,
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Thông báo nếu không đủ tiền
            if (!canAfford)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Số dư tài khoản không đủ. Vui lòng nạp thêm tiền.",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: canAfford && !_isProcessing ? _handlePayment : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    "XÁC NHẬN THANH TOÁN",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(int value, String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPaymentMethod = value);
        // Navigate to CardPaymentScreen if card option is selected
        if (value == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CardPaymentScreen(
                totalAmount: widget.totalAmount,
                customerName: widget.customerName,
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedPaymentMethod == value ? Colors.pink : Colors.transparent,
            width: 2,
          ),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.pink),
            const SizedBox(width: 15),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
            if (_selectedPaymentMethod == value)
              const Icon(Icons.check_circle, color: Colors.pink),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isAmount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isAmount ? Colors.pink : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, int amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          "${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ",
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.pink : Colors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);

    try {
      // Nếu chọn MoMo Account (option 1), mở WebView
      if (_selectedPaymentMethod == 1) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        
        // Call MoMo API to create payment link
        final orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
        final notifyUrl = 'https://example.com/momo-notify';
        final returnUrl = 'https://example.com/momo-return';

        final response = await MomoApiService.createPayment(
          orderId: orderId,
          amount: widget.totalAmount,
          orderInfo: 'Thanh toán đơn hàng',
          customerName: widget.customerName,
          customerPhone: widget.phoneNumber,
          notifyUrl: notifyUrl,
          returnUrl: returnUrl,
        );

        if (response != null && response.isSuccess()) {
          final paymentUrl = response.getPaymentUrl();
          if (paymentUrl != null && paymentUrl.isNotEmpty) {
            if (!mounted) return;
            setState(() => _isProcessing = false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MomoWebviewScreen(
                  totalAmount: widget.totalAmount,
                  customerName: widget.customerName,
                  phoneNumber: widget.phoneNumber,
                  paymentUrl: paymentUrl,
                ),
              ),
            );
            return;
          }
        }

        if (!mounted) return;
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tạo yêu cầu thanh toán: ${response?.resultMessage ?? 'Unknown'}')),
        );
        return;
      }

      // Các phương thức thanh toán khác xử lý ở đây
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      setState(() => _isProcessing = false);

      // Điều hướng tới màn hình xác nhận
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentConfirmationScreen(
            totalAmount: widget.totalAmount,
            customerName: widget.customerName,
            phoneNumber: widget.phoneNumber,
            paymentMethod: "MoMo",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi thanh toán: $e")),
      );
    }
  }
}
