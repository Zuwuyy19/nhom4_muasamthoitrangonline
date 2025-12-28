import 'package:firebase_database/firebase_database.dart';

import '../models/cart_models.dart';

class OrderService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  DatabaseReference _ordersRef() => _db.child('orders');

  Stream<List<OrderModel>> watchOrdersByUser(String uid) {
    return _ordersRef().orderByChild('userId').equalTo(uid).onValue.map((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        final orders = data.entries
            .where((entry) => entry.key is String && entry.value is Map)
            .map((entry) => OrderModel.fromMap(entry.key as String, entry.value as Map))
            .toList();
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return orders;
      }
      return <OrderModel>[];
    });
  }

  Future<String> createOrder({
    required String userId,
    required String userName,
    required int totalAmount,
    required String status,
    required List<OrderItem> items,
    required String paymentMethod,
    required String paymentStatus,
  }) async {
    final ref = _ordersRef().push();
    final paidAt = paymentStatus == 'success' ? ServerValue.timestamp : null;
    await ref.set({
      'userId': userId,
      'userName': userName,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': ServerValue.timestamp,
      'items': items.map((e) => e.toMap()).toList(),
      'payment': {
        'method': paymentMethod,
        'status': paymentStatus,
        if (paidAt != null) 'paidAt': paidAt,
      },
    });
    return ref.key ?? '';
  }
}
