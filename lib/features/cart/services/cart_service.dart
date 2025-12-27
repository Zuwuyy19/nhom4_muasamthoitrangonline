import 'package:firebase_database/firebase_database.dart';

import '../models/cart_models.dart';

class CartService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  DatabaseReference _cartRef(String uid) => _db.child('users').child(uid).child('cart');

  Stream<List<CartItem>> watchCart(String uid) {
    return _cartRef(uid).onValue.map((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        return data.entries
            .where((entry) => entry.key is String && entry.value is Map)
            .map((entry) => CartItem.fromMap(entry.key as String, entry.value as Map))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return <CartItem>[];
    });
  }

  Future<List<CartItem>> fetchCart(String uid) async {
    final snap = await _cartRef(uid).get();
    final data = snap.value;
    if (data is Map) {
      return data.entries
          .where((entry) => entry.key is String && entry.value is Map)
          .map((entry) => CartItem.fromMap(entry.key as String, entry.value as Map))
          .toList();
    }
    return <CartItem>[];
  }

  Future<void> addOrUpdateItem({
    required String uid,
    required String productId,
    required String productName,
    required int price,
    required int quantity,
    required String thumbnail,
  }) async {
    final ref = _cartRef(uid).child(productId);
    final snap = await ref.get();
    if (snap.exists && snap.value is Map) {
      final current = CartItem.fromMap(productId, snap.value as Map);
      await ref.update({
        'quantity': current.quantity + quantity,
      });
      return;
    }
    await ref.set({
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'thumbnail': thumbnail,
      'createdAt': ServerValue.timestamp,
    });
  }

  Future<void> updateQuantity({
    required String uid,
    required String productId,
    required int quantity,
  }) async {
    final ref = _cartRef(uid).child(productId);
    if (quantity <= 0) {
      await ref.remove();
      return;
    }
    await ref.update({'quantity': quantity});
  }

  Future<void> removeItem({
    required String uid,
    required String productId,
  }) async {
    await _cartRef(uid).child(productId).remove();
  }

  Future<void> clearCart(String uid) async {
    await _cartRef(uid).remove();
  }
}
