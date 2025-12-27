import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../auth/screens/login_screen.dart';
import '../../cart/models/cart_models.dart';
import '../../cart/services/cart_service.dart';
import '../../cart/services/wishlist_service.dart';
import '../../cart/screens/checkout_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  String _formatPrice(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final wishlistService = WishlistService();
    final cartService = CartService();

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wishlist')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Vui lòng đăng nhập để xem wishlist'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Wishlist', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<WishlistItem>>(
        stream: wishlistService.watchWishlist(user.uid),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  const Text('Wishlist của bạn đang trống', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.thumbnail,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
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
                          const SizedBox(height: 6),
                          Text('${_formatPrice(item.price)}đ'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    await cartService.addOrUpdateItem(
                                      uid: user.uid,
                                      productId: item.productId,
                                      productName: item.productName,
                                      price: item.price,
                                      quantity: 1,
                                      thumbnail: item.thumbnail,
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã thêm vào giỏ hàng')),
                                    );
                                  },
                                  child: const Text('Thêm vào giỏ'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await cartService.addOrUpdateItem(
                                      uid: user.uid,
                                      productId: item.productId,
                                      productName: item.productName,
                                      price: item.price,
                                      quantity: 1,
                                      thumbnail: item.thumbnail,
                                    );
                                    if (!context.mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CheckoutScreen(totalAmount: item.price),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                                  child: const Text('Mua ngay', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => wishlistService.removeItem(
                        uid: user.uid,
                        productId: item.productId,
                      ),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
