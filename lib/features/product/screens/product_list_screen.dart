// lib/product/screens/product_list_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

final DatabaseReference _productsRef = FirebaseDatabase.instance.ref('products');
final DatabaseReference _categoriesRef = FirebaseDatabase.instance.ref('categories');

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _selectedCategoryKey = 'all';

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

  List<Map<String, dynamic>> _parseProducts(dynamic data) {
    final List<Map<String, dynamic>> loaded = [];
    if (data is Map) {
      data.forEach((id, value) {
        if (id is String && value is Map) {
          final productData = Map<String, dynamic>.from(value);

          final name = (productData["name"] ?? "Sản phẩm").toString();
          final thumbnail = (productData["thumbnail"] ?? productData["image"] ?? "").toString();
          final categoryId = (productData["categoryId"] ?? productData["category"] ?? "all").toString();

          final priceRaw = productData["price"] ?? 0;
          final int priceInt = int.tryParse(priceRaw.toString()) ?? 0;
          final String formattedPrice = priceInt.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          );

          loaded.add({
            "id": id,
            "name": name,
            "thumbnail": thumbnail,
            "price": priceInt,
            "priceText": "${formattedPrice}đ",
            "categoryId": categoryId,
          });
        }
      });
    }
    return loaded;
  }

  List<Map<String, dynamic>> _filterByCategory(List<Map<String, dynamic>> products) {
    if (_selectedCategoryKey == 'all') return products;
    return products.where((p) => (p["categoryId"] ?? "").toString() == _selectedCategoryKey).toList();
  }

  void _openDetail(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          productId: (product["id"] ?? "").toString(),
          name: product["name"] ?? "Sản phẩm",
          price: product["price"] is int ? product["price"] as int : 0,
          thumbnail: (product["thumbnail"] ?? "").toString(),
          categoryId: (product["categoryId"] ?? "all").toString(),
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
            const Icon(Icons.search_off, size: 50, color: Colors.grey),
            const SizedBox(height: 10),
            Text(msg, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StreamBuilder<DatabaseEvent>(
              stream: _categoriesRef.onValue,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 44,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) return _noData('Lỗi tải danh mục: ${snap.error}');

                final categories = _parseCategories(snap.data?.snapshot.value);

                if (!categories.containsKey(_selectedCategoryKey)) {
                  _selectedCategoryKey = 'all';
                }

                final keys = categories.keys.toList();
                keys.sort((a, b) {
                  if (a == 'all') return -1;
                  if (b == 'all') return 1;
                  return (categories[a] ?? '').compareTo(categories[b] ?? '');
                });

                return SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: keys.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final key = keys[i];
                      final name = categories[key] ?? key;
                      final selected = key == _selectedCategoryKey;

                      return ChoiceChip(
                        label: Text(
                          name,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: selected,
                        selectedColor: Colors.black,
                        backgroundColor: Colors.white,
                        onSelected: (_) => setState(() => _selectedCategoryKey = key),
                        shape: StadiumBorder(
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _productsRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) return _noData('Lỗi tải sản phẩm: ${snapshot.error}');

                  final allProducts = _parseProducts(snapshot.data?.snapshot.value);
                  final filtered = _filterByCategory(allProducts);

                  if (filtered.isEmpty) return _noData('Không có sản phẩm trong danh mục này.');

                  return GridView.builder(
                    itemCount: filtered.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
