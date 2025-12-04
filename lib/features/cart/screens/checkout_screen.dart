import 'package:flutter/material.dart';
// Import Home để quay về sau khi đặt hàng thành công
import '../../home/screens/home_screen.dart'; 

class CheckoutScreen extends StatefulWidget {
  final int totalAmount; // Nhận tổng tiền từ giỏ hàng sang

  const CheckoutScreen({super.key, required this.totalAmount});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  int _paymentMethod = 1; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Thanh toán", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. THÔNG TIN GIAO HÀNG
              const Text("Địa chỉ nhận hàng", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              
              _buildTextField("Họ và tên", Icons.person, "Vui lòng nhập tên"),
              const SizedBox(height: 15),
              _buildTextField("Số điện thoại", Icons.phone, "Vui lòng nhập số điện thoại", isNumber: true),
              const SizedBox(height: 15),
              _buildTextField("Địa chỉ chi tiết", Icons.location_on, "Vui lòng nhập địa chỉ"),
              
              const SizedBox(height: 10),

              // --- MỚI THÊM: NÚT CHỌN BẢN ĐỒ (GIAO DIỆN) ---
              InkWell(
                onTap: () {
                  // Sau này tích hợp Google Maps ở đây
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Tính năng Bản đồ đang phát triển...")),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1), // Màu xanh nhạt
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.map_outlined, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        "Chọn vị trí trên bản đồ",
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              // ---------------------------------------------

              const SizedBox(height: 30),

              // 2. PHƯƠNG THỨC THANH TOÁN
              const Text("Phương thức thanh toán", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              
              _buildPaymentOption(1, "Thanh toán khi nhận hàng (COD)", Icons.money, Colors.green),
              const SizedBox(height: 10),
              _buildPaymentOption(2, "Ví điện tử MoMo / ZaloPay", Icons.account_balance_wallet, Colors.pink),

              const SizedBox(height: 30),

              // 3. TÓM TẮT ĐƠN HÀNG
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    _buildSummaryRow("Tạm tính", widget.totalAmount),
                    const SizedBox(height: 10),
                    _buildSummaryRow("Phí vận chuyển", 30000),
                    const Divider(height: 30),
                    _buildSummaryRow("Tổng thanh toán", widget.totalAmount + 30000, isTotal: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: _handleOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("XÁC NHẬN ĐẶT HÀNG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, String errorMsg, {bool isNumber = false}) {
    return TextFormField(
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      validator: (value) => (value == null || value.isEmpty) ? errorMsg : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildPaymentOption(int value, String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _paymentMethod == value ? Colors.black : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 5)],
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 15),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
            if (_paymentMethod == value) const Icon(Icons.check_circle, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, int amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(
          "${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ",
          style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? Colors.orange : Colors.black),
        ),
      ],
    );
  }

  void _handleOrder() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              const Text("Đặt hàng thành công!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  onPressed: () {
                    // Reset về trang chủ
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text("Tiếp tục mua sắm", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      );
    }
  }
}