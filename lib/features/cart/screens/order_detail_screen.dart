import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  final int totalAmount;
  final String customerName;
  final String phoneNumber;
  final String paymentMethod;
  final DateTime paidAt;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
    required this.customerName,
    required this.phoneNumber,
    required this.paymentMethod,
    required this.paidAt,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chi tiết đơn hàng",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard(
              title: "Thông tin đơn",
              child: Column(
                children: [
                  _rowItem("Mã đơn hàng", orderId, bold: true),
                  const Divider(height: 24),
                  _rowItem(
                    "Thời gian",
                    paidAt.toString().split('.')[0],
                  ),
                  const SizedBox(height: 8),
                  _rowItem("Phương thức", paymentMethod),
                  const SizedBox(height: 8),
                  _rowItem(
                    "Tổng tiền",
                    _formatCurrency(totalAmount),
                    highlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: "Khách hàng",
              child: Column(
                children: [
                  _rowItem("Họ và tên", customerName),
                  const Divider(height: 24),
                  _rowItem("Số điện thoại", phoneNumber),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "Quay lại",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _rowItem(String label, String value, {bool bold = false, bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold || highlight ? FontWeight.bold : FontWeight.normal,
            color: highlight ? Colors.pink : Colors.black,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  String _formatCurrency(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return "$formattedđ";
  }
}

