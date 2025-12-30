import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

final DatabaseReference _productsRef = FirebaseDatabase.instance.ref('products');
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

  // fallback cũ: products/images là List
  List<String> _parseImages(dynamic imagesRaw, String fallback) {
    final List<String> imgs = [];
    if (imagesRaw is List) {
      for (final x in imagesRaw) {
        final s = (x ?? '').toString().trim();
        if (s.isNotEmpty) imgs.add(s);
      }
    }
    final fb = fallback.trim();
    if (imgs.isEmpty && fb.isNotEmpty) imgs.add(fb);
    return imgs;
  }

  // sizes: ["S","M"...]
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

  // variants: Map<String,dynamic>
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

          String cardThumb = baseThumb;
          if (variants.isNotEmpty) {
            final firstKey = variants.keys.first;
            final v = variants[firstKey];
            if (v is Map) {
              final t = (v["thumbnail"] ?? "").toString().trim();
              if (t.isNotEmpty) cardThumb = t;
              final rawImgs = v["images"];
              if (t.isEmpty && rawImgs is List && rawImgs.isNotEmpty) {
                final firstImg =
                    (rawImgs.first ?? "").toString().trim();
                if (firstImg.isNotEmpty) cardThumb = firstImg;
              }
            }
          }

          final priceRaw = productData["price"] ?? 0;
          final int priceInt =
              int.tryParse(priceRaw.toString()) ?? 0;

          final String formattedPrice =
              priceInt.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          );

          loaded.add({
            "id": id,
            "name": name,
            "thumbnail": cardThumb,
            "baseThumb": baseThumb,
            "price": priceInt,
            "priceText": "${formattedPrice}đ",
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

  List<Map<String, dynamic>> _filterByCategory(
      List<Map<String, dynamic>> products) {
    if (_selectedCategoryKey == 'all') return products;
    return products
        .where((p) =>
            (p["categoryId"] ?? "").toString() ==
            _selectedCategoryKey)
        .toList();
  }

  // ✅ NEW: tìm kiếm theo tên sản phẩm
  List<Map<String, dynamic>> _filterBySearch(
      List<Map<String, dynamic>> products) {
    if (_searchText.trim().isEmpty) return products;
    final keyword = _searchText.toLowerCase();
    return products.where((p) {
      final name = (p["name"] ?? "").toString().toLowerCase();
      return name.contains(keyword);
    }).toList();
  }

  void _openDetail(Map<String, dynamic> product) {
    final variants = (product["variants"] is Map)
        ? Map<String, dynamic>.from(product["variants"])
        : <String, dynamic>{};

    final sizes = (product["sizes"] is List)
        ? List<String>.from(product["sizes"])
        : <String>[];

    final baseThumb =
        (product["baseThumb"] ?? product["thumbnail"] ?? "")
            .toString();

    Map<String, dynamic> safeVariants = variants;
    if (safeVariants.isEmpty) {
      final imgs = (product["images"] is List)
          ? List<String>.from(product["images"])
          : <String>[];
      safeVariants = {
        "default": {
          "label": "Default",
          "thumbnail": baseThumb,
          "images": imgs.isNotEmpty ? imgs : [baseThumb],
        }
      };
    }

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

  Widget _noData(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off,
                size: 50, color: Colors.grey),
            const SizedBox(height: 10),
            Text(msg,
                style: const TextStyle(
                    fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Categories
            StreamBuilder<DatabaseEvent>(
              stream: _categoriesRef.onValue,
              builder: (context, snap) {
                if (snap.connectionState ==
                    ConnectionState.waiting) {
                  return const SizedBox(
                    height: 44,
                    child: Center(
                        child: CircularProgressIndicator()),
                  );
                }

                final categories =
                    _parseCategories(snap.data?.snapshot.value);

                if (!categories
                    .containsKey(_selectedCategoryKey)) {
                  _selectedCategoryKey = 'all';
                }

                final keys = categories.keys.toList()
                  ..sort((a, b) {
                    if (a == 'all') return -1;
                    if (b == 'all') return 1;
                    return (categories[a] ?? '')
                        .compareTo(categories[b] ?? '');
                  });

                return SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: keys.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final key = keys[i];
                      final selected =
                          key == _selectedCategoryKey;

                      return ChoiceChip(
                        label: Text(
                          categories[key] ?? key,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: selected,
                        selectedColor: Colors.black,
                        backgroundColor: Colors.white,
                        onSelected: (_) =>
                            setState(() => _selectedCategoryKey = key),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

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
              onChanged: (value) {
                setState(() => _searchText = value);
              },
            ),

            const SizedBox(height: 12),

            /// Products
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _productsRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final allProducts = _parseProducts(
                      snapshot.data?.snapshot.value);
                  final byCategory =
                      _filterByCategory(allProducts);
                  final filtered =
                      _filterBySearch(byCategory);

                  if (filtered.isEmpty) {
                    return _noData(
                        'Không có sản phẩm phù hợp.');
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
                        title: p["name"] ?? "Sản phẩm",
                        price: p["priceText"] ?? "N/A",
                        imageUrl: p["thumbnail"] ?? "",
                        onTap: () => _openDetail(p),
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
