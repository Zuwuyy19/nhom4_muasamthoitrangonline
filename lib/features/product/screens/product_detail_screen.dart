import 'package:flutter/material.dart';

class ProductDetailScreen extends StatefulWidget {
  // Nhận dữ liệu từ màn hình Home truyền sang
  final String name;
  final String price;
  final String imageUrl;

  const ProductDetailScreen({
    super.key,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // Biến lưu trạng thái người dùng đang chọn size/màu nào
  int selectedSizeIndex = 0;
  int selectedColorIndex = 0;

  final List<String> sizes = ["S", "M", "L", "XL", "XXL"];
  final List<Color> colors = [
    Colors.black,
    Colors.blue.shade900,
    Colors.brown,
    Colors.grey,
  ];

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước màn hình để chia tỷ lệ layout
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Dùng Stack để ảnh nằm dưới, nội dung đè lên trên
      body: Stack(
        children: [
          // 1. Ảnh nền full màn hình (chiếm 50% chiều cao)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.5,
            child: Image.network(
              widget.imageUrl,
              fit: BoxFit.cover,
            ),
          ),

          // 2. Nút Back và Yêu thích ở trên cùng
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nút Back custom
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
                // Nút Yêu thích
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_border, color: Colors.black),
                ),
              ],
            ),
          ),

          // 3. Panel Thông tin sản phẩm (Trượt từ dưới lên)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.55, // Chiếm 55% màn hình dưới
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
                  // Tên và Giá
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
                            const Text("Áo thun phong cách Unisex", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text(
                        widget.price,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 25),

                  // Chọn Size
                  const Text("Chọn Size", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                            // Logic đổi màu khi được chọn
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

                  // Chọn Màu
                  const Text("Chọn Màu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                          padding: const EdgeInsets.all(3), // Tạo viền bao quanh
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              // Viền cam nếu đang chọn, trong suốt nếu không chọn
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

                  const Spacer(), // Đẩy nút mua hàng xuống đáy

                  // Nút Thêm vào giỏ hàng
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // Xử lý thêm vào giỏ hàng tại đây
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Đã thêm size ${sizes[selectedSizeIndex]} vào giỏ!"))
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("Thêm vào giỏ hàng", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
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