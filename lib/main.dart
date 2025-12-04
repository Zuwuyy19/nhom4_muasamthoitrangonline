import 'package:flutter/material.dart';
// Thay đổi đường dẫn import bên dưới tùy theo nơi bạn lưu file HomeScreen
import 'features/home/screens/home_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Tắt chữ DEBUG đỏ ở góc phải
      title: 'Fashion Store',
      
      // Cấu hình Giao diện chung (Global Theme)
      // Chỉnh ở đây thì toàn bộ App sẽ thay đổi theo
      theme: ThemeData(
        // Màu chủ đạo
        primaryColor: Colors.black,
        
        // Màu nền mặc định cho các màn hình (Trắng pha xám nhẹ cho hiện đại)
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        
        // Cấu hình font chữ mặc định (nếu muốn dùng Google Fonts thì add sau)
        fontFamily: 'Roboto', 

        // Cấu hình AppBar mặc định (Trong suốt, chữ đen)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black, 
            fontSize: 20, 
            fontWeight: FontWeight.bold
          ),
        ),

        // Cấu hình Nút bấm (ElevatedButton) mặc định là màu đen, bo góc
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black, // Màu nền nút
            foregroundColor: Colors.white, // Màu chữ nút
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Bo góc 12
            ),
          ),
        ),
        
        // Cấu hình ô nhập liệu (TextField)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(12),
             borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),

      // Màn hình khởi động đầu tiên
      home: HomeScreen(), 
    );
  }
}