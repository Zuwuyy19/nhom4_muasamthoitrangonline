import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../product/widgets/product_card.dart';
import '../../product/screens/product_detail_screen.dart';
import '../../cart/screens/cart_screen.dart';
import '../../cart/models/cart_models.dart';
import '../../cart/services/cart_service.dart';

import '../../profile/screens/profile_screen.dart';

final DatabaseReference _productsRef = FirebaseDatabase.instance.ref('products');
final DatabaseReference _categoriesRef = FirebaseDatabase.instance.ref('categories');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final CartService _cartService = CartService();

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

  // fallback images (cũ): products/images là List
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

  // parse sizes: ["S","M"...]
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

  // parse variants: Map<String, dynamic>
  Map<String, dynamic> _parseVariants(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return {};
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

          final variants = _parseVariants(productData["variants"]);
          final sizes = _parseSizes(productData["sizes"]);

          // thumbnail hiển thị card:
          // - nếu có variants, lấy thumbnail của variant đầu tiên (nếu có)
          String cardThumb = thumbnail;
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
          final String formattedPrice = priceInt.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          );

          loaded.add({
            "id": id,
            "name": name,
            "thumbnail": cardThumb,     // dùng cho card
            "baseThumb": thumbnail,     // thumb gốc
            "price": priceInt,
            "priceText": "${formattedPrice}đ",
            "categoryId": categoryId,
            "variants": variants,       // ✅ NEW
            "sizes": sizes,             // ✅ NEW
            "images": _parseImages(productData["images"], thumbnail), // fallback cũ
          });
        }
      });
    }
    return loaded;
  }

  List<Map<String, dynamic>> _filterByCategory(List<Map<String, dynamic>> products, String categoryKey) {
    if (categoryKey == 'all') return products;
    return products.where((p) => (p["categoryId"] ?? "").toString() == categoryKey).toList();
  }

  void _openDetail(Map<String, dynamic> product) {
    final variants = (product["variants"] is Map)
        ? Map<String, dynamic>.from(product["variants"])
        : <String, dynamic>{};

    final sizes = (product["sizes"] is List)
        ? List<String>.from(product["sizes"])
        : <String>[];

    // thumbnail truyền vào detail: ưu tiên baseThumb (image cũ)
    final baseThumb = (product["baseThumb"] ?? product["thumbnail"] ?? "").toString();

    // Nếu DB chưa có variants, vẫn cho chạy: tạo variant giả từ images cũ
    Map<String, dynamic> safeVariants = variants;
    if (safeVariants.isEmpty) {
      final imgs = (product["images"] is List) ? List<String>.from(product["images"]) : <String>[];
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
          productId: (product["id"] ?? "").toString(),
          name: (product["name"] ?? "Sản phẩm").toString(),
          price: product["price"] is int ? product["price"] as int : 0,
          thumbnail: baseThumb,
          categoryId: (product["categoryId"] ?? "all").toString(),
          variants: safeVariants, // ✅ truyền variants
          sizes: sizes,           // ✅ truyền sizes
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Chào mừng đến shop 👋",
              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.normal),
            ),
            Text("HUTECH Fashion", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                  if (!mounted) return;
                  if (result == 'go_products') setState(() => _selectedIndex = 1);
                },
                icon: const Icon(Icons.shopping_bag_outlined),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: StreamBuilder<List<CartItem>>(
                  stream: FirebaseAuth.instance.currentUser == null
                      ? null
                      : _cartService.watchCart(FirebaseAuth.instance.currentUser!.uid),
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? [];
                    final count = items.fold<int>(0, (sum, item) => sum + item.quantity);
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: _pageForIndex(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: 'Sản phẩm'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Giỏ hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Tài khoản'),
        ],
      ),
    );
  }

  Widget _pageForIndex(int index) {
    switch (index) {
      case 0:
        return _homeContent();
      case 1:
        return _productsPageWithCategories();
      case 2:
        return CartScreen(onGoShopping: () => setState(() => _selectedIndex = 1));
      case 3:
        return const ProfileScreen();
      default:
        return _homeContent();
    }
  }

  Widget _homeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: NetworkImage("https://cdn.pixabay.com/photo/2017/08/01/11/48/woman-2564660_1280.jpg"),
                fit: BoxFit.cover,
                opacity: 0.6,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Bộ sưu tập mới", style: TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 5),
                const Text(
                  "GIẢM GIÁ\nMÙA HÈ 50%",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text("Xem sản phẩm", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text("Sản phẩm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          StreamBuilder<DatabaseEvent>(
            stream: _productsRef.onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.only(top: 30), child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) return _noData('Lỗi tải dữ liệu: ${snapshot.error}');
              final all = _parseProducts(snapshot.data?.snapshot.value);
              if (all.isEmpty) return _noData('Chưa có sản phẩm.');

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: all.length > 6 ? 6 : all.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemBuilder: (_, i) {
                  final p = all[i];
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
        ],
      ),
    );
  }

  Widget _productsPageWithCategories() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          StreamBuilder<DatabaseEvent>(
            stream: _categoriesRef.onValue,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 44, child: Center(child: CircularProgressIndicator()));
              }
              if (snap.hasError) return _noData('Lỗi tải danh mục: ${snap.error}');

              final categories = _parseCategories(snap.data?.snapshot.value);
              if (!categories.containsKey(_selectedCategoryKey)) _selectedCategoryKey = 'all';

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
                        style: TextStyle(color: selected ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
                      ),
                      selected: selected,
                      selectedColor: Colors.black,
                      backgroundColor: Colors.white,
                      onSelected: (_) => setState(() => _selectedCategoryKey = key),
                      shape: StadiumBorder(side: BorderSide(color: Colors.grey.shade300)),
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
                final filtered = _filterByCategory(allProducts, _selectedCategoryKey);
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
    );
  }
}
