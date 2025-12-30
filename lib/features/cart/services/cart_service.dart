import 'package:firebase_database/firebase_database.dart';
import '../models/cart_models.dart';

class CartService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  DatabaseReference _cartRef(String uid) =>
      _db.child('users').child(uid).child('cart');

  // ✅ Tạo key riêng theo biến thể: productId__size__color
  String _makeCartKey({
    required String productId,
    String? size,
    String? color,
  }) {
    final s = (size ?? '').trim();
    final c = (color ?? '').trim();
    final safeS = s.isEmpty ? 'nosize' : s;
    final safeC = c.isEmpty ? 'nocolor' : c;
    return '${productId}__${safeS}__${safeC}';
  }

  Stream<List<CartItem>> watchCart(String uid) {
    return _cartRef(uid).onValue.map((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        final items = data.entries
            .where((e) => e.key is String && e.value is Map)
            .map((e) => CartItem.fromMap(e.key as String, e.value as Map))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return items;
      }
      return <CartItem>[];
    });
  }

  Future<List<CartItem>> fetchCart(String uid) async {
    final snap = await _cartRef(uid).get();
    final data = snap.value;
    if (data is Map) {
      return data.entries
          .where((e) => e.key is String && e.value is Map)
          .map((e) => CartItem.fromMap(e.key as String, e.value as Map))
          .toList();
    }
    return <CartItem>[];
  }

  /// ✅ add theo biến thể (size/color)
  /// - nếu cùng productId + size + color => cộng quantity
  Future<void> addOrUpdateItem({
    required String uid,
    required String productId,
    required String productName,
    required int price,
    required int quantity,
    required String thumbnail,
    String? size,
    String? color, // ✅ label
  }) async {
    final s = (size ?? '').trim();
    final c = (color ?? '').trim();

    final cartKey = _makeCartKey(productId: productId, size: s, color: c);
    final ref = _cartRef(uid).child(cartKey);

    final snap = await ref.get();
    if (snap.exists && snap.value is Map) {
      final current = CartItem.fromMap(cartKey, snap.value as Map);
      await ref.update({
        'quantity': current.quantity + quantity,
        'thumbnail': thumbnail,
        'price': price,
        'productName': productName,
        if (s.isNotEmpty) 'size': s,
        if (c.isNotEmpty) 'color': c,
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
      if (s.isNotEmpty) 'size': s,
      if (c.isNotEmpty) 'color': c,
    });
  }

  Future<void> updateQuantity({
    required String uid,
    required String cartKey, // ✅ đổi productId -> cartKey
    required int quantity,
  }) async {
    final ref = _cartRef(uid).child(cartKey);
    if (quantity <= 0) {
      await ref.remove();
      return;
    }
    await ref.update({'quantity': quantity});
  }

  Future<void> removeItem({
    required String uid,
    required String cartKey, // ✅ đổi productId -> cartKey
  }) async {
    await _cartRef(uid).child(cartKey).remove();
  }

  Future<void> clearCart(String uid) async {
    await _cartRef(uid).remove();
  }
}
