import 'package:flutter/material.dart';

// Import đúng đường dẫn package của bạn
import 'package:nhom4_muasamthoitrangonline/features/product/widgets/product_card.dart';
import 'package:nhom4_muasamthoitrangonline/features/product/screens/product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  // Đã dùng super.key chuẩn rồi
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> categories = ["Tất cả", "Áo thun", "Sơ mi", "Quần Jeans", "Giày", "Phụ kiện"];
  int selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> products = [
    {
      "name": "Áo Thun Oversize HUTECH",
      "price": "150.000đ",
      "image": "https://cdn.pixabay.com/photo/2016/11/22/19/08/hangers-1850082_1280.jpg"
    },
    {
      "name": "Quần Jeans Slimfit",
      "price": "350.000đ",
      "image": "https://cdn.pixabay.com/photo/2014/08/26/21/48/jeans-428613_1280.jpg"
    },
    {
      "name": "Sneaker Trắng Basic",
      "price": "500.000đ",
      "image": "https://cdn.pixabay.com/photo/2016/11/19/18/06/feet-1840619_1280.jpg"
    },
    {
      "name": "Áo Hoodie Mùa Đông",
      "price": "420.000đ",
      "image": "https://cdn.pixabay.com/photo/2016/11/29/01/34/man-1866572_1280.jpg"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Xin chào, Vũ Huy 👋", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.normal)),
            Text("HUTECH Fashion", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.shopping_bag_outlined)),
              Positioned(
                right: 8, top: 8,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SEARCH BAR (SỬA LỖI TẠI ĐÂY) ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    // SỬA LỖI: Thay withOpacity(0.1) -> withValues(alpha: 0.1)
                    color: Colors.grey.withValues(alpha: 0.1), 
                    blurRadius: 10, 
                    offset: const Offset(0, 5)
                  )
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
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

            // --- BANNER ---
            Container(
              width: double.infinity,
              height: 160,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Bộ sưu tập mới", style: TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 5),
                  const Text("GIẢM GIÁ\nMÙA HÈ 50%", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
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

            // --- CATEGORIES ---
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedCategoryIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => selectedCategoryIndex = index),
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

            // --- TITLE ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Sản phẩm nổi bật", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text("Xem tất cả", style: TextStyle(color: Colors.grey))),
              ],
            ),
            const SizedBox(height: 10),

            // --- GRID VIEW ---
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.7,
              ),
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  title: product["name"],
                  price: product["price"],
                  imageUrl: product["image"],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          name: product["name"],
                          price: product["price"],
                          imageUrl: product["image"],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}