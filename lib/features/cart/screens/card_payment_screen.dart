import 'package:flutter/material.dart';
import 'otp_verification_screen.dart';

class CardPaymentScreen extends StatefulWidget {
  final int totalAmount;
  final String customerName;
  final String phoneNumber;

  const CardPaymentScreen({
    super.key,
    required this.totalAmount,
    required this.customerName,
    required this.phoneNumber,
  });

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.phoneNumber;
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text("Thanh toán bằng thẻ", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.pink,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.pink,
            tabs: [
              Tab(text: "Thẻ quốc tế"),
              Tab(text: "Thẻ nội địa"),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  children: [
                    _buildCardForm(isCredit: true),
                    _buildCardForm(isCredit: false),
                  ],
                ),
              ),
            ),
          ],
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
              onPressed: _isProcessing ? null : _handleCardPayment,
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
                      "THANH TOÁN",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardForm({required bool isCredit}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: double.infinity,
              height: 220,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCredit
                      ? const [Color(0xFF8B5CF6), Color(0xFFE879F9)]
                      : const [Color(0xFF0EA5E9), Color(0xFF22C55E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: (isCredit ? Colors.pink : Colors.blue).withOpacity(0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.credit_card, color: Colors.white, size: 32),
                    Wrap(
                      spacing: 8,
                      children: isCredit
                          ? const [
                              _CardBrandChip(label: "VISA"),
                              _CardBrandChip(label: "Mastercard"),
                              _CardBrandChip(label: "JCB"),
                            ]
                          : const [
                              _CardBrandChip(label: "NAPAS"),
                            ],
                    ),
                    ],
                  ),
                  Text(
                    _cardNumberController.text.isEmpty
                        ? "•••• •••• •••• ••••"
                        : _cardNumberController.text.replaceAllMapped(
                            RegExp(r'.{1,4}'),
                            (match) => '${match.group(0)} ',
                          ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TÊN CHỦ THẺ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _cardHolderController.text.isEmpty
                                ? "NHẬP TÊN CHỦ THẺ"
                                : _cardHolderController.text.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "MM/YY",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _expiryDateController.text.isEmpty ? "MM/YY" : _expiryDateController.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isCredit
                        ? "Vui lòng dùng thẻ tín dụng/ghi nợ quốc tế (VISA/Mastercard/JCB) phát hành tại Việt Nam."
                        : "Thẻ ghi nợ nội địa/NAPAS: dùng thẻ do ngân hàng Việt Nam phát hành và đã bật thanh toán online.",
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Nhập thông tin thẻ để thanh toán",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          TextFormField(
            controller: _cardNumberController,
            readOnly: false,
            keyboardType: TextInputType.number,
            maxLength: 16,
            onChanged: (value) => setState(() {}),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập số thẻ';
              }
              final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
              if (digitsOnly.length != 16) {
                return 'Số thẻ phải gồm 16 chữ số';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Số thẻ',
              hintText: 'Nhập số thẻ',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryDateController,
                  keyboardType: TextInputType.datetime,
                  maxLength: 5,
                  readOnly: false,
                  onChanged: (value) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Nhập MM/YY";
                    }
                    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                      return "Định dạng MM/YY";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Ngày hết hạn",
                    hintText: "MM/YY",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          TextFormField(
            controller: _cardHolderController,
            keyboardType: TextInputType.name,
            readOnly: false,
            onChanged: (value) => setState(() {}),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Vui lòng nhập tên chủ thẻ";
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: "Tên chủ thẻ",
              prefixIcon: const Icon(Icons.person, color: Colors.grey),
              hintText: "Nhập tên chủ thẻ",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 15),

          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Vui lòng nhập số điện thoại";
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: "Số điện thoại",
              prefixIcon: const Icon(Icons.phone, color: Colors.grey),
              hintText: "0901234567",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Tổng cộng",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${widget.totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCardPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);

      try {
        final digitsOnly = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');

        // Với thẻ hợp lệ, tiếp tục luồng OTP
        if (!mounted) return;
        setState(() => _isProcessing = false);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              totalAmount: widget.totalAmount,
              customerName: widget.customerName,
              phoneNumber: widget.phoneNumber,
              cardNumber: _cardNumberController.text,
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
}

class _CardBrandChip extends StatelessWidget {
  final String label;
  const _CardBrandChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
