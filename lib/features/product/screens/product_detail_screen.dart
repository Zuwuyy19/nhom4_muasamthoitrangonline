import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../cart/services/cart_service.dart';
import '../../cart/services/wishlist_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String name;
  final int price;
  final String thumbnail;
  final String categoryId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    required this.thumbnail,
    required this.categoryId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int selectedSizeIndex = 0;
  int selectedColorIndex = 0;

  final List<String> sizes = ['S', 'M', 'L', 'XL', 'XXL'];
  final List<Color> colors = [
    Colors.black,
    Colors.blue,
    Colors.brown,
    Colors.grey,
  ];

  final CartService _cartService = CartService();
  final WishlistService _wishlistService = WishlistService();

  String _formatPrice(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng')),
      );
      return;
    }

    await _cartService.addOrUpdateItem(
      uid: user.uid,
      productId: widget.productId,
      productName: widget.name,
      price: widget.price,
      quantity: 1,
      thumbnail: widget.thumbnail,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm ${widget.name} vào giỏ hàng')),
    );
  }

  Future<void> _addToWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để thêm yêu thích')),
      );
      return;
    }

    await _wishlistService.addItem(
      uid: user.uid,
      productId: widget.productId,
      productName: widget.name,
      price: widget.price,
      thumbnail: widget.thumbnail,
      categoryId: widget.categoryId,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã thêm vào danh sách yêu thích')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.5,
            child: Image.network(
              widget.thumbnail,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported, size: 48),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                ),
                GestureDetector(
                  onTap: _addToWishlist,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.55,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            const Text('Mô tả sản phẩm', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text(
                        '${_formatPrice(widget.price)}đ',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Text('Chọn size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(sizes.length, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedSizeIndex = index;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 15),
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: selectedSizeIndex == index ? Colors.black : Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              sizes[index],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: selectedSizeIndex == index ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 25),
                  const Text('Chọn màu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(colors.length, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedColorIndex = index;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 15),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColorIndex == index ? Colors.orange : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: colors[index],
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text(
                        'Thêm vào giỏ hàng',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}