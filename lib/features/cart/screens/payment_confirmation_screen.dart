import 'package:flutter/material.dart';
import '../../home/screens/home_screen.dart' as home;
import 'order_detail_screen.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final int totalAmount;
  final String customerName;
  final String phoneNumber;
  final String paymentMethod;
  final String? orderId;
  final DateTime? paidAt;

  const PaymentConfirmationScreen({
    super.key,
    required this.totalAmount,
    required this.customerName,
    required this.phoneNumber,
    required this.paymentMethod,
    this.orderId,
    this.paidAt,
  });

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  late final String _orderId;
  late final DateTime _paidAt;

  @override
  void initState() {
    super.initState();
    _orderId = widget.orderId ?? "ORD-${DateTime.now().millisecondsSinceEpoch}";
    _paidAt = widget.paidAt ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- ICON THÀNH CÔNG ---
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 60),
              ),

              const SizedBox(height: 30),

              // --- TIÊU ĐỀ ---
              const Text(
                "Thanh toán thành công!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              Text(
                "Đơn hàng của bạn sẽ được giao trong 2-3 ngày",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // --- THẺ THÔNG TIN THANH TOÁN ---
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // --- PHƯƠNG THỨC THANH TOÁN ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.pink[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.paymentMethod == "MoMo"
                                ? Icons.account_balance_wallet
                                : Icons.credit_card,
                            color: Colors.pink,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.paymentMethod,
                            style: const TextStyle(
                              color: Colors.pink,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // --- SỐ TIỀN ---
                    const Text(
                      "Số tiền thanh toán",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${widget.totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- THÔNG TIN KHÁCH HÀNG ---
                    const Divider(thickness: 1),
                    const SizedBox(height: 15),

                    _buildInfoItem(
                      icon: Icons.person,
                      label: "Họ và tên",
                      value: widget.customerName,
                    ),

                    const SizedBox(height: 15),

                    _buildInfoItem(
                      icon: Icons.phone,
                      label: "Số điện thoại",
                      value: widget.phoneNumber,
                    ),

                    const SizedBox(height: 15),

                    _buildInfoItem(
                      icon: Icons.credit_card,
                      label: "Phương thức thanh toán",
                      value: widget.paymentMethod,
                    ),

                    const SizedBox(height: 15),

                    _buildInfoItem(
                      icon: Icons.calendar_today,
                      label: "Ngày thanh toán",
                      value: _paidAt.toString().split('.')[0],
                    ),

                    const SizedBox(height: 15),

                    _buildInfoItem(
                      icon: Icons.receipt_long,
                      label: "Mã đơn hàng",
                      value: _orderId,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- NÚT QUAY LẠI TRANG CHỦ ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const home.HomeScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Quay lại trang chủ",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // --- NÚT XEM CHI TIẾT ĐƠN HÀNG ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailScreen(
                          orderId: _orderId,
                          totalAmount: widget.totalAmount,
                          customerName: widget.customerName,
                          phoneNumber: widget.phoneNumber,
                          paymentMethod: widget.paymentMethod,
                          paidAt: _paidAt,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Xem chi tiết đơn hàng",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.pink, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
