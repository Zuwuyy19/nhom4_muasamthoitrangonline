import 'package:firebase_database/firebase_database.dart';

import '../models/cart_models.dart';

class WishlistService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  DatabaseReference _wishlistRef(String uid) => _db.child('users').child(uid).child('wishlist');

  Stream<List<WishlistItem>> watchWishlist(String uid) {
    return _wishlistRef(uid).onValue.map((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        return data.entries
            .where((entry) => entry.key is String && entry.value is Map)
            .map((entry) => WishlistItem.fromMap(entry.key as String, entry.value as Map))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return <WishlistItem>[];
    });
  }

  Future<void> addItem({
    required String uid,
    required String productId,
    required String productName,
    required int price,
    required String thumbnail,
    required String categoryId,
  }) async {
    await _wishlistRef(uid).child(productId).set({
      'productId': productId,
      'productName': productName,
      'price': price,
      'thumbnail': thumbnail,
      'categoryId': categoryId,
      'createdAt': ServerValue.timestamp,
    });
  }

  Future<void> removeItem({required String uid, required String productId}) async {
    await _wishlistRef(uid).child(productId).remove();
  }
}
