import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import '../../cart/services/cart_service.dart';
import '../../cart/services/wishlist_service.dart';

final DatabaseReference _productsRef =
    FirebaseDatabase.instance.ref('products');
final DatabaseReference _categoriesRef =
    FirebaseDatabase.instance.ref('categories');

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _selectedCategoryKey = 'all';
  String _searchText = '';

  final CartService _cartService = CartService();
  final WishlistService _wishlistService = WishlistService();

  // ========================
  // PARSE HELPERS
  // ========================
  Map<String, String> _parseCategories(dynamic data) {
    final Map<String, String> result = {};
    if (data is Map) {
      data.forEach((k, v) {
        if (k is String) result[k] = (v ?? '').toString();
      });
    }
    result.putIfAbsent('all', () => 'Tất cả');
    return result;
  }

  List<String> _parseImages(dynamic imagesRaw, String fallback) {
    final List<String> imgs = [];
    if (imagesRaw is List) {
      for (final x in imagesRaw) {
        final s = (x ?? '').toString().trim();
        if (s.isNotEmpty) imgs.add(s);
      }
    }
    if (imgs.isEmpty && fallback.trim().isNotEmpty) {
      imgs.add(fallback.trim());
    }
    return imgs;
  }

  List<String> _parseSizes(dynamic sizesRaw) {
    final List<String> out = [];
    if (sizesRaw is List) {
      for (final x in sizesRaw) {
        final s = (x ?? '').toString().trim();
        if (s.isNotEmpty) out.add(s);
      }
    }
    return out;
  }

  Map<String, dynamic> _parseVariants(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  List<Map<String, dynamic>> _parseProducts(dynamic data) {
    final List<Map<String, dynamic>> loaded = [];
    if (data is Map) {
      data.forEach((id, value) {
        if (id is String && value is Map) {
          final productData = Map<String, dynamic>.from(value);

          final name = (productData["name"] ?? "Sản phẩm").toString();
          final baseThumb =
              (productData["thumbnail"] ?? productData["image"] ?? "")
                  .toString();

          final categoryId =
              (productData["categoryId"] ?? productData["category"] ?? "all")
                  .toString();

          final variants = _parseVariants(productData["variants"]);
          final sizes = _parseSizes(productData["sizes"]);

          // thumbnail ưu tiên variant đầu
          String cardThumb = baseThumb;
          if (variants.isNotEmpty) {
            final firstKey = variants.keys.first;
            final v = variants[firstKey];
            if (v is Map) {
              final t = (v["thumbnail"] ?? "").toString().trim();
              if (t.isNotEmpty) cardThumb = t;
            }
          }

          final priceRaw = productData["price"] ?? 0;
          final int priceInt = int.tryParse(priceRaw.toString()) ?? 0;

          final String formattedPrice =
              priceInt.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          );

          loaded.add({
            "id": id,
            "name": name,
            "thumbnail": cardThumb,
            "baseThumb": baseThumb,
            "price": priceInt,
            "priceText": "$formattedPriceđ",
            "categoryId": categoryId,
            "variants": variants,
            "sizes": sizes,
            "images": _parseImages(productData["images"], baseThumb),
          });
        }
      });
    }
    return loaded;
  }

  // ========================
  // FILTER
  // ========================
  List<Map<String, dynamic>> _filterByCategory(
      List<Map<String, dynamic>> products) {
    if (_selectedCategoryKey == 'all') return products;
    return products
        .where((p) =>
            (p["categoryId"] ?? "").toString() == _selectedCategoryKey)
        .toList();
  }

  List<Map<String, dynamic>> _filterBySearch(
      List<Map<String, dynamic>> products) {
    if (_searchText.trim().isEmpty) return products;
    final keyword = _searchText.toLowerCase();
    return products.where((p) {
      final name = (p["name"] ?? "").toString().toLowerCase();
      return name.contains(keyword);
    }).toList();
  }

  // ========================
  // QUICK ACTIONS
  // ========================
  Future<void> _quickAddToCart(Map<String, dynamic> p) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng')),
      );
      return;
    }

    final variants = (p["variants"] is Map)
        ? Map<String, dynamic>.from(p["variants"])
        : <String, dynamic>{};

    String finalThumb = (p["baseThumb"] ?? p["thumbnail"] ?? "").toString();
    String? colorLabel;

    if (variants.isNotEmpty) {
      final firstKey = variants.keys.first;
      final v = variants[firstKey];
      if (v is Map) {
        colorLabel = (v["label"] ?? "").toString().trim();
        final t = (v["thumbnail"] ?? "").toString().trim();
        if (t.isNotEmpty) finalThumb = t;
      }
    }

    await _cartService.addOrUpdateItem(
      uid: user.uid,
      productId: p["id"].toString(),
      productName: p["name"].toString(),
      price: p["price"] as int,
      quantity: 1,
      thumbnail: finalThumb,
      size: null, // list screen chưa chọn size
      color: colorLabel,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm vào giỏ: ${p["name"]}')),
    );
  }

  Future<void> _quickAddToWishlist(Map<String, dynamic> p) async {
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
      productId: p["id"].toString(),
      productName: p["name"].toString(),
      price: p["price"] as int,
      thumbnail: (p["baseThumb"] ?? p["thumbnail"] ?? "").toString(),
      categoryId: p["categoryId"].toString(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã thêm vào yêu thích')),
    );
  }

  // ========================
  // OPEN DETAIL
  // ========================
  void _openDetail(Map<String, dynamic> product) {
    final variants = (product["variants"] is Map)
        ? Map<String, dynamic>.from(product["variants"])
        : <String, dynamic>{};

    final sizes = (product["sizes"] is List)
        ? List<String>.from(product["sizes"])
        : <String>[];

    final baseThumb =
        (product["baseThumb"] ?? product["thumbnail"] ?? "").toString();

    final safeVariants = variants.isEmpty
        ? {
            "default": {
              "label": "Default",
              "thumbnail": baseThumb,
              "images": [baseThumb],
            }
          }
        : variants;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          productId: product["id"].toString(),
          name: product["name"].toString(),
          price: product["price"] as int,
          thumbnail: baseThumb,
          categoryId: product["categoryId"].toString(),
          variants: safeVariants,
          sizes: sizes,
        ),
      ),
    );
  }

  // ========================
  // UI
  // ========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Search
            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm ...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _searchText = v),
            ),

            const SizedBox(height: 12),

            /// Products
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _productsRef.onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final allProducts =
                      _parseProducts(snapshot.data!.snapshot.value);
                  final filtered = _filterBySearch(allProducts);

                  if (filtered.isEmpty) {
                    return const Center(
                        child: Text('Không có sản phẩm phù hợp'));
                  }

                  return GridView.builder(
                    itemCount: filtered.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      return ProductCard(
                        title: p["name"],
                        price: p["priceText"],
                        imageUrl: p["thumbnail"],
                        onTap: () => _openDetail(p),
                        onAddToCart: () => _quickAddToCart(p),
                        onAddToWishlist: () => _quickAddToWishlist(p),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
