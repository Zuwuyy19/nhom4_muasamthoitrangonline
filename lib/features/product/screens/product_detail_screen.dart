import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../cart/services/cart_service.dart';
import '../../cart/services/wishlist_service.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String name;
  final int price;
  final String thumbnail;
  final String categoryId;

  final Map<String, dynamic> variants; // { "white": {label, thumbnail, images: []}, ... }
  final List<String> sizes; // ["S","M"...] hoặc ["27","27.5","EU 42"]...

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

  List<String> _imagesForSelectedVariant() {
    if (widget.variants.isNotEmpty && _selectedVariantKey != null) {
      final v = widget.variants[_selectedVariantKey];
      if (v is Map) {
        final raw = v["images"];
        if (raw is List) {
          final imgs = raw
              .map((e) => (e ?? '').toString().trim())
              .where((s) => s.isNotEmpty)
              .toList();
          if (imgs.isNotEmpty) return imgs;
        }
      }
    }
    final fb = widget.thumbnail.trim();
    return fb.isNotEmpty ? [fb] : [];
  }

  String _thumbnailForVariant(String key) {
    final v = widget.variants[key];
    if (v is Map) {
      final t = (v["thumbnail"] ?? "").toString().trim();
      if (t.isNotEmpty) return t;

      final raw = v["images"];
      if (raw is List && raw.isNotEmpty) {
        final first = (raw.first ?? "").toString().trim();
        if (first.isNotEmpty) return first;
      }
    }
    return widget.thumbnail;
  }

  String _labelForVariant(String key) {
    final v = widget.variants[key];
    if (v is Map) {
      final label = (v["label"] ?? "").toString().trim();
      if (label.isNotEmpty) return label;
    }
    return key;
  }

  // ✅ FIX: addToCart có size + color(label) + thumbnail theo variant
  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng')),
      );
      return;
    }

    // size
    String? selectedSize;
    if (widget.sizes.isNotEmpty) {
      if (selectedSizeIndex < 0 || selectedSizeIndex >= widget.sizes.length) {
        selectedSizeIndex = 0;
      }
      final s = widget.sizes[selectedSizeIndex].trim();
      selectedSize = s.isEmpty ? null : s;
    }

    // color
    final colorKey = _selectedVariantKey?.trim();
    if (widget.variants.isNotEmpty && (colorKey == null || colorKey.isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn màu trước khi thêm vào giỏ')),
      );
      return;
    }

    String? colorLabel;
    String finalThumb = widget.thumbnail;

    if (widget.variants.isNotEmpty && colorKey != null && widget.variants[colorKey] is Map) {
      final v = Map<String, dynamic>.from(widget.variants[colorKey] as Map);

      final label = (v['label'] ?? '').toString().trim();
      if (label.isNotEmpty) colorLabel = label;

      final thumb = (v['thumbnail'] ?? '').toString().trim();
      if (thumb.isNotEmpty) finalThumb = thumb;
    }

    colorLabel ??= colorKey;

    await _cartService.addOrUpdateItem(
      uid: user.uid,
      productId: widget.productId,
      productName: widget.name,
      price: widget.price,
      quantity: 1,
      thumbnail: finalThumb,
      size: selectedSize,
      color: colorLabel,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã thêm: ${widget.name}'
          '${colorLabel != null && colorLabel!.trim().isNotEmpty ? " - $colorLabel" : ""}'
          '${selectedSize != null ? " / $selectedSize" : ""}',
        ),
      ),
    );
  }

  Future<void> _addToWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
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

    final images = _imagesForSelectedVariant();
    if (_activeImageIndex >= images.length) _activeImageIndex = 0;

    final hasSizes = widget.sizes.isNotEmpty;
    final hasVariants = widget.variants.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.5,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageCtrl,
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _activeImageIndex = i),
                  itemBuilder: (context, i) {
                    final url = images[i];
                    return GestureDetector(
                      onTap: () {
                        final imageProviders = images.map((u) => Image.network(u).image).toList();
                        final multiImageProvider = MultiImageProvider(imageProviders, initialIndex: i);
                        showImageViewerPager(context, multiImageProvider);
                      },
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported, size: 48),
                        ),
                      ),
                    );
                  },
                ),
                if (images.length > 1)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(images.length, (i) {
                        final active = i == _activeImageIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 18 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active ? Colors.white : Colors.white70,
                            borderRadius: BorderRadius.circular(50),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
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
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                ),
                GestureDetector(
                  onTap: _addToWishlist,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
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

                  if (hasVariants) ...[
                    const SizedBox(height: 18),
                    const Text('Màu sắc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 64,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.variants.keys.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final key = widget.variants.keys.elementAt(i);
                          final selected = key == _selectedVariantKey;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedVariantKey = key;
                                _activeImageIndex = 0;
                              });
                              if (_pageCtrl.hasClients) _pageCtrl.jumpToPage(0);
                            },
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected ? Colors.orange : Colors.grey.shade300,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.network(
                                _thumbnailForVariant(key),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedVariantKey == null ? '' : _labelForVariant(_selectedVariantKey!),
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                    ),
                  ],

                  if (hasSizes) ...[
                    const SizedBox(height: 18),
                    const Text('Chọn size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(widget.sizes.length, (index) {
                          final s = widget.sizes[index];
                          final selected = selectedSizeIndex == index;

                          return GestureDetector(
                            onTap: () => setState(() => selectedSizeIndex = index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              constraints: const BoxConstraints(minWidth: 60, minHeight: 48),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected ? Colors.black : Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                s,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: selected ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],

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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
