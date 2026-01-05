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
  
  // Biến phục vụ chức năng tìm kiếm
  // Biến phục vụ chức năng tìm kiếm
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  // fallback images
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

  // parse sizes
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

  // parse variants
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
            "thumbnail": cardThumb,
            "baseThumb": thumbnail,
            "price": priceInt,
            "priceText": "${formattedPrice}đ",
            "categoryId": categoryId,
            "variants": variants,
            "sizes": sizes,
            "images": _parseImages(productData["images"], thumbnail),
          });
        }
      });
    }
    return loaded;
  }

  // Cập nhật logic lọc: Lọc theo cả danh mục và từ khóa tìm kiếm
  List<Map<String, dynamic>> _filterProducts(List<Map<String, dynamic>> products, String categoryKey, String query) {
    return products.where((p) {
      final name = (p["name"] ?? "").toString().toLowerCase();
      final matchesCategory = (categoryKey == 'all' || (p["categoryId"] ?? "").toString() == categoryKey);
      final matchesSearch = name.contains(query.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _openDetail(Map<String, dynamic> product) {
    final variants = (product["variants"] is Map)
        ? Map<String, dynamic>.from(product["variants"])
        : <String, dynamic>{};

    final sizes = (product["sizes"] is List)
        ? List<String>.from(product["sizes"])
        : <String>[];

    final baseThumb = (product["baseThumb"] ?? product["thumbnail"] ?? "").toString();

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
    final bool isSearching = _searchQuery.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thanh tìm kiếm
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: "Tìm kiếm sản phẩm...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear), 
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    }
                  ) 
                : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
          const SizedBox(height: 20),

          // Banner & Title (chỉ hiển thị khi không tìm kiếm)
          if (!isSearching) ...[
            HomeBannerSlider(
              onShopNow: () => setState(() => _selectedIndex = 1),
            ),
            const SizedBox(height: 18),
            const Text("Sản phẩm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
          ],

          // Grid sản phẩm
          StreamBuilder<DatabaseEvent>(
            stream: _productsRef.onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.only(top: 30), child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) return _noData('Lỗi tải dữ liệu: ${snapshot.error}');
              
              final all = _parseProducts(snapshot.data?.snapshot.value);
              List<Map<String, dynamic>> displayList = [];

              if (isSearching) {
                // Lọc theo từ khóa (category 'all')
                displayList = _filterProducts(all, 'all', _searchQuery);
                if (displayList.isEmpty) return _noData('Không tìm thấy sản phẩm nào.');
              } else {
                // Mặc định hiển thị 6 sản phẩm
                displayList = all.length > 6 ? all.sublist(0, 6) : all;
                if (displayList.isEmpty) return _noData('Chưa có sản phẩm.');
              }

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: displayList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                  itemBuilder: (_, i) {
                    final p = displayList[i];
                    return ProductCard(
                      id: (p["id"] ?? "").toString(),
                      title: p["name"] ?? "Sản phẩm",
                      price: p["priceText"] ?? "N/A",
                      priceInt: p["price"] is int ? p["price"] : 0,
                      imageUrl: p["thumbnail"] ?? "",
                      categoryId: (p["categoryId"] ?? "all").toString(),
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
          // --- PHẦN TÌM KIẾM MỚI ---
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: "Tìm kiếm sản phẩm...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear), 
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    }
                  ) 
                : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
          const SizedBox(height: 16),
          // --- HẾT PHẦN TÌM KIẾM ---

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
                
                // Sử dụng hàm lọc mới cho cả Category và Search
                final filtered = _filterProducts(allProducts, _selectedCategoryKey, _searchQuery);
                
                if (filtered.isEmpty) return _noData('Không tìm thấy sản phẩm nào.');

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
                      id: (p["id"] ?? "").toString(),
                      title: p["name"] ?? "Sản phẩm",
                      price: p["priceText"] ?? "N/A",
                      priceInt: p["price"] is int ? p["price"] : 0,
                      imageUrl: p["thumbnail"] ?? "",
                      categoryId: (p["categoryId"] ?? "all").toString(),
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

class HomeBannerSlider extends StatefulWidget {
  final VoidCallback onShopNow;

  const HomeBannerSlider({super.key, required this.onShopNow});

  @override
  State<HomeBannerSlider> createState() => _HomeBannerSliderState();
}

class _HomeBannerSliderState extends State<HomeBannerSlider> {
  late PageController _bannerCtrl;
  int _bannerIndex = 0;

  final List<Map<String, String>> _banners = [
    {
      "image": "https://cdn.pixabay.com/photo/2017/08/01/11/48/woman-2564660_1280.jpg",
      "subtitle": "Bộ sưu tập mới",
      "title": "GIẢM GIÁ\nMÙA HÈ 50%"
    },
    {
      "image": "https://edeninterior.vn/wp-content/uploads/2022/05/thiet-ke-shop-thoi-trang-nu-peggy.jpg",
      "subtitle": "Thời trang năng động",
      "title": "NĂNG ĐỘNG\nCHO GEN Z"
    },
    {
      "image": "https://upcontent.vn/wp-content/uploads/2024/07/mau-banner-shop-giay-1-1024x640.jpg",
      "subtitle": "Phụ kiện cao cấp",
      "title": "GIẢM 30%\nCHO GIÀY"
    },
  ];

  @override
  void initState() {
    super.initState();
    _bannerCtrl = PageController();
  }

  @override
  void dispose() {
    _bannerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _bannerCtrl,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _bannerIndex = i),
            itemBuilder: (_, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(banner["image"]!),
                    fit: BoxFit.cover,
                    opacity: 0.6,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(banner["subtitle"]!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 5),
                    Text(
                      banner["title"]!,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: widget.onShopNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text("Xem ngay", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = i == _bannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? Colors.black : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }
}