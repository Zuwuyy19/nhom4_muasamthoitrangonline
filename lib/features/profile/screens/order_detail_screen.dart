import 'package:flutter/material.dart';

import '../../cart/models/cart_models.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  String _formatPrice(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  String _formatDate(int millis) {
    if (millis == 0) return '---';
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[50],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            title: 'Thông tin đơn',
            child: Column(
              children: [
                _rowItem('Mã đơn hàng', order.id, bold: true),
                const Divider(height: 24),
                _rowItem('Ngày tạo', _formatDate(order.createdAt)),
                const SizedBox(height: 8),
                _rowItem('Trạng thái', order.status),
                const SizedBox(height: 8),
                _rowItem('Tổng tiền', '${_formatPrice(order.totalAmount)}đ', highlight: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Thanh toán',
            child: Column(
              children: [
                _rowItem('Phương thức', order.payment.method),
                const Divider(height: 24),
                _rowItem('Trạng thái', order.payment.status),
                const SizedBox(height: 8),
                _rowItem(
                  'Thanh toán lúc',
                  order.payment.paidAt == null ? '---' : _formatDate(order.payment.paidAt!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Sản phẩm',
            child: Column(
              children: order.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              item.thumbnail,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 64,
                                height: 64,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatPrice(item.price)}đ x${item.quantity}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
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
}
