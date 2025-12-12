// lib/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart'; 

// Import các màn hình khác (Dùng đường dẫn tương đối)
import '../../product/widgets/product_card.dart';
import '../../product/screens/product_detail_screen.dart';
import '../../cart/screens/cart_screen.dart'; 

// Khai báo tham chiếu đến node 'products' trong Realtime Database
final DatabaseReference _productsRef = FirebaseDatabase.instance.ref('products');


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  // Dữ liệu gốc (đã chuẩn hóa) và dữ liệu lọc
  List<Map<String, dynamic>> _allProducts = []; 
  List<Map<String, dynamic>> _filteredProducts = [];
  
  final List<String> categories = ["Tất cả", "Áo thun", "Sơ mi", "Quần Jeans", "Giày", "Phụ kiện"];
  int selectedCategoryIndex = 0;
  String _searchKeyword = ""; 
  
  // Trạng thái loading/đã tải dữ liệu ban đầu
  bool _isDataLoadedAndFiltered = false;

  @override
  void initState() {
    super.initState();
    _filteredProducts = _allProducts;
  }
  
  // --- HÀM TẢI, ÉP KIỂU VÀ CHUẨN HÓA DỮ LIỆU TỪ FIREBASE ---
  // Hàm này KHÔNG gọi setState. Nó chỉ xử lý và cập nhật các biến State.
  void _loadAndStandardizeProducts(Map<String, dynamic>? rawProductsMap) {
    if (!mounted) return;

    List<Map<String, dynamic>> loadedProducts = [];
    
    if (rawProductsMap != null && rawProductsMap.isNotEmpty) {
        rawProductsMap.forEach((id, data) {
          if (data is Map) {
            Map<String, dynamic> productData = Map<String, dynamic>.from(data as Map);

            // Xử lý giá (đảm bảo price là Number trong Firebase)
            final priceRaw = productData["price"] ?? 0;
            // Ép giá về int để định dạng
            final int priceInt = int.tryParse(priceRaw.toString()) ?? 0;
            
            final String formattedPrice = priceInt.toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
                (Match m) => '${m[1]}.'
            );
            
            loadedProducts.add({
              "id": id,
              "name": productData["name"] ?? "Sản phẩm không tên",
              "price": "${formattedPrice}đ", 
              "image": productData["image"] ?? "",
              "category": productData["category"] ?? "Tất cả",
            });
          }
        });
    }

    // Cập nhật _allProducts
    _allProducts = loadedProducts; 
    
    // Áp dụng bộ lọc cho dữ liệu mới nhất
    _applyFilterLogic(_searchKeyword, selectedCategoryIndex);
    
    // Thiết lập cờ đã tải dữ liệu
    _isDataLoadedAndFiltered = true;
    
    // Cập nhật UI (Sẽ được gọi từ _callSetStateSafely)
  }
  
  // Hàm này được gọi từ các widget tương tác hoặc sau khi tải Firebase để đảm bảo UI cập nhật
  void _callSetStateSafely() {
      if (mounted) {
          setState(() {
              // Hàm này chỉ kích hoạt build()
          });
      }
  }
  
  // Hàm chạy logic lọc (KHÔNG gọi setState)
  void _applyFilterLogic(String enteredKeyword, int categoryIndex) {
      _searchKeyword = enteredKeyword;
      selectedCategoryIndex = categoryIndex;

      List<Map<String, dynamic>> results = _allProducts;
      String keyword = _searchKeyword.toLowerCase();
      
      // LỌC THEO TỪ KHÓA
      if (keyword.isNotEmpty) {
        results = results
            .where((product) =>
                product["name"].toLowerCase().contains(keyword))
            .toList();
      }
      
      // LỌC THEO DANH MỤC
      final selectedCategory = categories[selectedCategoryIndex];
      if (selectedCategory != "Tất cả") {
        results = results.where((product) => 
            product["category"]?.toString().toLowerCase() == selectedCategory.toLowerCase()
        ).toList();
      }

      // Cập nhật _filteredProducts mà KHÔNG gọi setState
      _filteredProducts = results; 
  }


  // Widget hiển thị khi không tìm thấy sản phẩm
  Widget _buildNoProductFound({String message = "Không tìm thấy sản phẩm nào."}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          const Icon(Icons.search_off, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- APP BAR (Giữ nguyên) ---
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Chào mừng đến shop 👋",
              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.normal),
            ),
            Text(
              "HUTECH Fashion",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()), 
                  );
                }, 
                icon: const Icon(Icons.shopping_bag_outlined)
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                ),
              )
            ],
          )
        ],
      ),
      
      body: _selectedIndex == 0 ? _homeContent() : _pageForIndex(_selectedIndex),
      
      // --- BOTTOM NAVIGATION BAR (Giữ nguyên) ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: 'Danh mục'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Giỏ hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Tài khoản'),
        ],
      ),
    );
  }

  // Tách phần nội dung màn hình chính
  Widget _homeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. THANH TÌM KIẾM (SEARCH BAR) ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10, 
                  offset: const Offset(0, 5)
                )
              ],
            ),
            child: TextField(
              onChanged: (value) {
                  // Áp dụng bộ lọc và kích hoạt UI cập nhật
                  _applyFilterLogic(value, selectedCategoryIndex); 
                  _callSetStateSafely(); 
              }, 
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                hintText: "Tìm kiếm sản phẩm...",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          
          const SizedBox(height: 25),

          // --- 2. BANNER (Giữ nguyên) ---
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
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                ),
                
                const Spacer(), 
                
                ElevatedButton(
                  onPressed: () {}, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, 
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text("Xem ngay", style: TextStyle(fontSize: 12)),
                )
              ],
            ),
          ),

          const SizedBox(height: 25),

          // --- 3. DANH MỤC (CATEGORIES) ---
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final isSelected = selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () {
                    // Áp dụng bộ lọc và kích hoạt UI cập nhật
                    _applyFilterLogic(_searchKeyword, index);
                    _callSetStateSafely(); 
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 15),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        categories[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 25),

          // --- 4. TIÊU ĐỀ KẾT QUẢ TÌM KIẾM ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Sản phẩm nổi bật", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () {}, child: const Text("Xem tất cả", style: TextStyle(color: Colors.grey))),
            ],
          ),
          
          const SizedBox(height: 10),

          // --- GRID VIEW HIỂN THỊ KẾT QUẢ (StreamBuilder) ---
          StreamBuilder<DatabaseEvent>(
            stream: _productsRef.onValue,
            builder: (context, snapshot) {
              
              // *******************************************************************
              // 1. XỬ LÝ DỮ LIỆU FIREBASE VÀ GỌI setState SAU BUILD
              // *******************************************************************
              final data = snapshot.data?.snapshot.value;
              final Map<String, dynamic> productsMap = {};

              if (data != null && data is Map) {
                  (data as Map).forEach((key, value) {
                    if (key is String && value is Map) {
                        productsMap[key] = Map<String, dynamic>.from(value);
                    }
                  });
              }

              // Chỉ gọi cập nhật State nếu dữ liệu mới (productsMap) khác _allProducts
              // Nếu StreamBuilder có data mới (sau khi tải xong), ta gọi cập nhật
              if (snapshot.connectionState != ConnectionState.waiting) {
                  // Chỉ gọi cập nhật khi có sự kiện từ Stream
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                      // Kiểm tra xem dữ liệu mới có khác dữ liệu cũ không (để tránh vòng lặp)
                      // Dù lỗi log lặp đã được sửa, kiểm tra này vẫn tốt cho hiệu suất
                      if (productsMap.length != _allProducts.length || snapshot.data!.snapshot.value != null) {
                         _loadAndStandardizeProducts(productsMap);
                         _callSetStateSafely(); 
                      }
                  });
              }
              
              
              // *******************************************************************
              // 2. LOGIC HIỂN THỊ UI
              // *******************************************************************

              // A. Loading ban đầu
              if (!_isDataLoadedAndFiltered) {
                 return const Center(child: Padding(
                   padding: EdgeInsets.only(top: 50.0),
                   child: CircularProgressIndicator(),
                 ));
              }

              // B. Hiển thị Lỗi
              if (snapshot.hasError) {
                  return _buildNoProductFound(message: 'Lỗi tải dữ liệu: ${snapshot.error}');
              }

              // C. Hiển thị Không tìm thấy sản phẩm
              if (_filteredProducts.isEmpty) {
                  return _buildNoProductFound(message: "Không tìm thấy sản phẩm nào.");
              }
              
              // D. Hiển thị Grid View
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _filteredProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.7,
                ),
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  
                  return ProductCard(
                    title: product["name"] ?? "Sản phẩm",
                    price: product["price"] ?? "N/A", 
                    imageUrl: product["image"] ?? "",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            name: product["name"] ?? "Sản phẩm",
                            price: product["price"] ?? "N/A",
                            imageUrl: product["image"] ?? "",
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _pageForIndex(int index) {
    switch (index) {
      case 1:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.grid_view_outlined, size: 56, color: Colors.grey),
              SizedBox(height: 8),
              Text('Danh mục', style: TextStyle(fontSize: 18)),
            ],
          ),
        );
      case 2:
        return const CartScreen();
      case 3:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.person_outline, size: 56, color: Colors.grey),
              SizedBox(height: 8),
              Text('Tài khoản', style: TextStyle(fontSize: 18)),
            ],
          ),
        );
      default:
        return _homeContent();
    }
  }
}