import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../cart/services/cart_service.dart';
import '../../cart/services/wishlist_service.dart';
import 'product_image_viewer.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String name;
  final int price;
  final String thumbnail;
  final String categoryId;

  final Map<String, dynamic> variants;
  final List<String> sizes;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    required this.thumbnail,
    required this.categoryId,
    required this.variants,
    required this.sizes,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int selectedSizeIndex = 0;
  String? _selectedVariantKey;

  final CartService _cartService = CartService();
  final WishlistService _wishlistService = WishlistService();

  final PageController _pageCtrl = PageController();
  int _activeImageIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.variants.isNotEmpty) {
      _selectedVariantKey = widget.variants.keys.first;
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  String _formatPrice(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  // ================= IMAGES =================
  List<String> _imagesForSelectedVariant() {
    if (_selectedVariantKey != null &&
        widget.variants[_selectedVariantKey] is Map) {
      final v = widget.variants[_selectedVariantKey];
      final raw = v['images'];
      if (raw is List) {
        final imgs = raw
            .map((e) => (e ?? '').toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (imgs.isNotEmpty) return imgs;
      }
    }
    return widget.thumbnail.trim().isNotEmpty
        ? [widget.thumbnail]
        : [];
  }

  String _thumbnailForVariant(String key) {
    final v = widget.variants[key];
    if (v is Map) {
      final t = (v['thumbnail'] ?? '').toString().trim();
      if (t.isNotEmpty) return t;
    }
    return widget.thumbnail;
  }

  String _labelForVariant(String key) {
    final v = widget.variants[key];
    if (v is Map) {
      final label = (v['label'] ?? '').toString().trim();
      if (label.isNotEmpty) return label;
    }
    return key;
  }

  // ================= ACTIONS =================
  Future<void> _addToWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
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
      const SnackBar(content: Text('Đã thêm vào yêu thích')),
    );
  }

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
      );
      return;
    }

    final size = widget.sizes.isNotEmpty
        ? widget.sizes[selectedSizeIndex]
        : null;

    await _cartService.addOrUpdateItem(
      uid: user.uid,
      productId: widget.productId,
      productName: widget.name,
      price: widget.price,
      quantity: 1,
      thumbnail: widget.thumbnail,
      size: size,
      color: _selectedVariantKey,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã thêm vào giỏ hàng')),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final sizeScreen = MediaQuery.of(context).size;
    final images = _imagesForSelectedVariant();

    final hasSizes = widget.sizes.isNotEmpty;
    final hasVariants = widget.variants.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          // ================= IMAGE (CHỈ THÊM TAP PHÓNG TO) =================
          SizedBox(
            height: sizeScreen.height * 0.5,
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _activeImageIndex = i),
              itemBuilder: (context, i) {
                final url = images[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductImageViewer(
                          images: images,
                          initialIndex: i,
                        ),
                      ),
                    );
                  },
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported, size: 48),
                    ),
                  ),
                );
              },
            ),
          ),

          // ================= TOP BAR =================
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleBtn(Icons.arrow_back,
                    () => Navigator.pop(context)),
                _circleBtn(Icons.favorite_border, _addToWishlist),
              ],
            ),
          ),

          // ================= CONTENT =================
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: sizeScreen.height * 0.55,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // name + price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.name,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${_formatPrice(widget.price)}đ',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  // ====== COLOR ======
                  if (hasVariants) ...[
                    const SizedBox(height: 18),
                    const Text('Màu sắc',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 64,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.variants.keys.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final key =
                              widget.variants.keys.elementAt(i);
                          final selected =
                              key == _selectedVariantKey;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedVariantKey = key;
                                _activeImageIndex = 0;
                              });
                              _pageCtrl.jumpToPage(0);
                            },
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? Colors.orange
                                      : Colors.grey.shade300,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.network(
                                _thumbnailForVariant(key),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedVariantKey == null
                          ? ''
                          : _labelForVariant(_selectedVariantKey!),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600),
                    ),
                  ],

                  // ====== SIZE ======
                  if (hasSizes) ...[
                    const SizedBox(height: 18),
                    const Text('Chọn size',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(widget.sizes.length,
                            (index) {
                          final selected =
                              selectedSizeIndex == index;
                          return GestureDetector(
                            onTap: () => setState(
                                () => selectedSizeIndex = index),
                            child: Container(
                              margin:
                                  const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.black
                                    : Colors.white,
                                borderRadius:
                                    BorderRadius.circular(14),
                                border: Border.all(
                                    color:
                                        Colors.grey.shade300),
                              ),
                              child: Text(
                                widget.sizes[index],
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // ====== ADD TO CART ======
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Thêm vào giỏ hàng',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon),
      ),
    );
  }
}
