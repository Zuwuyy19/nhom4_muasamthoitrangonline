import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Dữ liệu giả
  List<Map<String, dynamic>> cartItems = [
    {
      "name": "Áo Thun Oversize HUTECH",
      "price": 150000,
      "image": "https://cdn.pixabay.com/photo/2016/11/22/19/08/hangers-1850082_1280.jpg",
      "size": "L",
      "color": Colors.black,
      "quantity": 1,
    },
    {
      "name": "Quần Jeans Slimfit",
      "price": 350000,
      "image": "https://cdn.pixabay.com/photo/2014/08/26/21/48/jeans-428613_1280.jpg",
      "size": "29",
      "color": Colors.blue,
      "quantity": 2,
    },
  ];

  // Hàm tính tổng tiền
  int get totalPrice {
    int total = 0;
    for (var item in cartItems) {
      total += (item['price'] as int) * (item['quantity'] as int);
    }
    return total;
  }

  // Hàm xử lý xóa sản phẩm (Có hiện hộp thoại xác nhận)
  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc muốn xóa sản phẩm này khỏi giỏ hàng không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(), // Đóng hộp thoại
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              // Thực hiện xóa
              setState(() {
                cartItems.removeAt(index);
              });
              Navigator.of(ctx).pop(); // Đóng hộp thoại
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đã xóa sản phẩm thành công!")),
              );
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Giỏ hàng của bạn", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                // DANH SÁCH SẢN PHẨM
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      // Vẫn giữ tính năng Vuốt để xóa
                      return Dismissible(
                        key: Key(item['name'] + index.toString()), // Key unique
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          // Trả về true nếu muốn xóa, false nếu hủy
                          // Ở đây mình cho xóa luôn khi vuốt cho nhanh
                          return true;
                        },
                        onDismissed: (direction) {
                          setState(() {
                            cartItems.removeAt(index);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Đã xóa sản phẩm")),
                          );
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: _buildCartItem(item, index),
                      );
                    },
                  ),
                ),

                // BOTTOM BAR: TỔNG TIỀN & THANH TOÁN
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Tổng cộng:", style: TextStyle(fontSize: 16, color: Colors.grey)),
                          Text(
                            "${totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Tính năng thanh toán đang phát triển...")),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text("Tiến hành thanh toán", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }

  // Widget hiển thị từng món hàng (ĐÃ CẬP NHẬT GIAO DIỆN)
  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 5)],
      ),
      child: Row(
        children: [
          // 1. Ảnh sản phẩm
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: NetworkImage(item['image']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 15),
          
          // 2. Thông tin chi tiết
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng 1: Tên + Nút Xóa (Icon thùng rác)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item['name'], 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis
                      ),
                    ),
                    // NÚT XÓA Ở ĐÂY
                    GestureDetector(
                      onTap: () => _deleteItem(index),
                      child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    )
                  ],
                ),
                
                const SizedBox(height: 5),
                Text("Size: ${item['size']} | Màu: Đen", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 10),
                
                // Hàng 3: Giá + Nút tăng giảm số lượng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${item['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                    ),
                    
                    Container(
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 14),
                            onPressed: () {
                              if (item['quantity'] > 1) {
                                setState(() {
                                  item['quantity']--;
                                });
                              } else {
                                // Nếu số lượng = 1 mà bấm trừ thì hỏi xóa luôn
                                _deleteItem(index);
                              }
                            },
                          ),
                          Text("${item['quantity']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          IconButton(
                            icon: const Icon(Icons.add, size: 14),
                            onPressed: () {
                              setState(() {
                                item['quantity']++;
                              });
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị khi giỏ hàng trống
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text("Giỏ hàng của bạn đang trống", style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            child: const Text("Đi mua sắm ngay", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}