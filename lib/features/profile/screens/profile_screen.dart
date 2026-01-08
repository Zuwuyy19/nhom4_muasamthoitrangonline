import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../auth/auth_service.dart';

import '../../auth/screens/login_screen.dart';
import '../../auth/screens/register_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../cart/models/cart_models.dart';
import '../../cart/services/wishlist_service.dart';
import '../../cart/services/order_service.dart';
import 'order_history_screen.dart';
import 'pending_orders_screen.dart';
import 'processing_orders_screen.dart';
import 'wishlist_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  final WishlistService _wishlistService = WishlistService();
  final OrderService _orderService = OrderService();

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openLogin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openRegister() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (!mounted) return;
    setState(() {});
  }

Future<void> _handleSignOut() async {
  try {
    await AuthService().logout(); // ✅ logout cả Google + Firebase

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đăng xuất lỗi: $e")),
    );
  }
}

  void _requireLogin(String action) {
    _showMessage(context, 'Vui lòng đăng nhập để $action');
  }

  Future<void> _sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _showMessage(context, 'Đã gửi email đặt lại mật khẩu');
    } catch (e) {
      if (!mounted) return;
      _showMessage(context, 'Không thể gửi email: $e');
    }
  }

  Future<void> _editProfile({
    required String uid,
    required String fullName,
    required String phone,
    required String address,
  }) async {
    final nameCtrl = TextEditingController(text: fullName);
    final phoneCtrl = TextEditingController(text: phone);
    final addressCtrl = TextEditingController(text: address);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Chỉnh sửa thông tin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Lưu thay đổi'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (result != true) return;

    try {
      await _usersRef.child(uid).update({
        'fullName': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
      });
      await FirebaseAuth.instance.currentUser?.updateDisplayName(
        nameCtrl.text.trim(),
      );
      if (!mounted) return;
      _showMessage(context, 'Đã cập nhật thông tin');
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      _showMessage(context, 'Không thể cập nhật: $e');
    }
  }

  Future<void> _pickAndUploadImage(String uid) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500, // Reduced size for RTDB
        maxHeight: 500,
        imageQuality: 70, // Reduced quality for RTDB
      );
      
      if (pickedFile == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang xử lý ảnh...')),
      );

      final bytes = await File(pickedFile.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      await _usersRef.child(uid).update({
        'photoBase64': base64Image,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật ảnh đại diện thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật ảnh: $e')),
      );
    }
  }

  Map<String, dynamic> _mapFromSnapshot(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value as Map);
    }
    return {};
  }

  String _getString(Map<String, dynamic> data, String key, String fallback) {
    final value = data[key];
    if (value == null) return fallback;
    return value.toString();
  }

  String _formatCreatedAt(Map<String, dynamic> data) {
    final raw = data['createdAt'];
    final millis = int.tryParse(raw?.toString() ?? '');
if (millis == null) return '---';
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  void _showPersonalInfo({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String role,
    required String createdAt,
  }) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Xem thông tin cá nhân',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _InfoRow(label: 'Họ và tên', value: fullName),
              _InfoRow(label: 'Email', value: email),
              _InfoRow(label: 'Số điện thoại', value: phone),
              _InfoRow(label: 'Địa chỉ', value: address),
              _InfoRow(label: 'Vai trò', value: role),
              _InfoRow(label: 'Ngày tạo', value: createdAt),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Guest is technically "logged in" with anonymous auth, so user != null.
    // We check user.isAnonymous to distinguish.
    final isGuest = user == null || user.isAnonymous;

    if (isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hồ sơ (Khách)')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileHeader(
                displayName: 'Khách (Guest)',
                email: 'Đăng nhập để xem thông tin tài khoản',
                isGuest: true,
                onEdit: () {},
                onLogin: _openLogin,
                onRegister: _openRegister,
              ),
              const SizedBox(height: 16),
              _QuickStatsRow(
                wishlistCount: '0',
                pendingCount: '0',
                processingCount: '0',
                onCart: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WishlistScreen()),
                ),
                onPendingConfirm: () =>
                    _requireLogin('xem đơn hàng chờ xác nhận'),
                onShipping: () => _requireLogin('xem đơn chờ giao'),
              ),
              const SizedBox(height: 20),
              const _SectionHeader(title: 'Tài khoản'),
              _ProfileTile(
                title: 'Chỉnh sửa thông tin cá nhân',
                subtitle: 'Cập nhật tên, email, số điện thoại',
icon: Icons.person_outline,
                onTap: () => _requireLogin('chỉnh sửa thông tin'),
              ),
              _ProfileTile(
                title: 'Đổi mật khẩu',
                subtitle: 'Bảo mật tài khoản của bạn',
                icon: Icons.lock_outline,
                onTap: () => _requireLogin('đổi mật khẩu'),
              ),
              _ProfileTile(
                title: 'Địa chỉ giao hàng',
                subtitle: 'Quản lý địa chỉ mặc định',
                icon: Icons.location_on_outlined,
                onTap: () => _requireLogin('quản lý địa chỉ'),
              ),
              const SizedBox(height: 16),
              const _SectionHeader(title: 'Đơn hàng'),
              _ProfileTile(
                title: 'Lịch sử đơn hàng',
                subtitle: 'Xem chi tiết các đơn đã mua',
                icon: Icons.receipt_long_outlined,
                onTap: () => _requireLogin('xem lịch sử đơn hàng'),
              ),
              _ProfileTile(
                title: 'Đơn hàng đang xử lý',
                subtitle: 'Theo dõi trạng thái vận chuyển',
                icon: Icons.local_shipping_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProcessingOrdersScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _SectionHeader(title: 'Hỗ trợ'),
              _ProfileTile(
                title: 'Trung tâm trợ giúp',
                subtitle: 'Câu hỏi thường gặp và hỗ trợ',
                icon: Icons.help_outline,
                onTap: () => _showMessage(context, 'Mở trung tâm trợ giúp'),
              ),
              _ProfileTile(
                title: 'Cài đặt',
                subtitle: 'Thông báo, bảo mật, ngôn ngữ',
                icon: Icons.settings_outlined,
                onTap: () => _showMessage(context, 'Mở cài đặt'),
              ),
              _ProfileTile(
                title: 'Đăng nhập',
                subtitle: 'Truy cập đầy đủ tính năng',
                icon: Icons.login,
                onTap: _openLogin,
              ),
            ],
          ),
        ),
      );
    }

    final uid = user!.uid;

    return StreamBuilder<DatabaseEvent>(
      stream: _usersRef.child(uid).onValue,
      builder: (context, snapshot) {
        final data = _mapFromSnapshot(snapshot.data?.snapshot.value);
        final fullName = _getString(
          data,
          'fullName',
          user.displayName ?? 'HUTECH Member',
        );
        final email = _getString(data, 'email', user.email ?? '');
        final phone = _getString(data, 'phone', '---');
        final address = _getString(data, 'address', '---');
        final role = _getString(data, 'role', 'customer');
        final photoBase64 = _getString(data, 'photoBase64', '');
        final createdAt = _formatCreatedAt(data);

        return Scaffold(
appBar: AppBar(
            title: const Text('Hồ sơ'),
            actions: [
              IconButton(
                onPressed: () => _showPersonalInfo(
                  fullName: fullName,
                  email: email,
                  phone: phone,
                  address: address,
                  role: role,
                  createdAt: createdAt,
                ),
                icon: const Icon(Icons.info_outline),
                tooltip: 'Xem thông tin cá nhân',
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ProfileHeader(
                  displayName: fullName,
                  email: email,
                  photoBase64: photoBase64,
                  isGuest: false,
                  onEdit: () => _pickAndUploadImage(uid),
                  onLogin: _openLogin,
                  onRegister: _openRegister,
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<WishlistItem>>(
                  stream: _wishlistService.watchWishlist(uid),
                  builder: (context, snapshot) {
                    final count = (snapshot.data ?? []).length;
                    return StreamBuilder<List<OrderModel>>(
                      stream: _orderService.watchOrdersByUser(uid),
                      builder: (context, orderSnapshot) {
                        final orders = orderSnapshot.data ?? [];
                        final pendingCount = orders
                            .where((o) => o.status == 'pending')
                            .length;
                        final processingCount = orders
                            .where((o) => o.status == 'processing')
                            .length;
                        return _QuickStatsRow(
                          wishlistCount: count.toString(),
                          pendingCount: pendingCount.toString(),
                          processingCount: processingCount.toString(),
                          onCart: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WishlistScreen(),
                            ),
                          ),
                          onPendingConfirm: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PendingOrdersScreen(),
                            ),
                          ),
                          onShipping: () => Navigator.push(
                            context,
MaterialPageRoute(
                              builder: (_) => const ProcessingOrdersScreen(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                const _SectionHeader(title: 'Tài khoản'),
                _ProfileTile(
                  title: 'Chỉnh sửa thông tin cá nhân',
                  subtitle: 'Cập nhật tên, số điện thoại, địa chỉ',
                  icon: Icons.person_outline,
                  onTap: () => _editProfile(
                    uid: uid,
                    fullName: fullName,
                    phone: phone == '---' ? '' : phone,
                    address: address == '---' ? '' : address,
                  ),
                ),
                _ProfileTile(
                  title: 'Đổi mật khẩu',
                  subtitle: 'Thay đổi mật khẩu đăng nhập',
                  icon: Icons.lock_outline,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  ),
                ),
                _ProfileTile(
                  title: 'Địa chỉ giao hàng',
                  subtitle: 'Quản lý địa chỉ mặc định',
                  icon: Icons.location_on_outlined,
                  onTap: () => _editProfile(
                    uid: uid,
                    fullName: fullName,
                    phone: phone == '---' ? '' : phone,
                    address: address == '---' ? '' : address,
                  ),
                ),
                const SizedBox(height: 16),
                const _SectionHeader(title: 'Đơn hàng'),
                _ProfileTile(
                  title: 'Lịch sử đơn hàng',
                  subtitle: 'Xem chi tiết các đơn đã mua',
                  icon: Icons.receipt_long_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrderHistoryScreen(),
                    ),
                  ),
                ),
                _ProfileTile(
                  title: 'Đơn hàng đang xử lý',
                  subtitle: 'Theo dõi trạng thái vận chuyển',
                  icon: Icons.local_shipping_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProcessingOrdersScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _SectionHeader(title: 'Hỗ trợ'),
                _ProfileTile(
                  title: 'Trung tâm trợ giúp',
                  subtitle: 'Câu hỏi thường gặp và hỗ trợ',
                  icon: Icons.help_outline,
                  onTap: () => _showMessage(context, 'Mở trung tâm trợ giúp'),
                ),
                _ProfileTile(
title: 'Cài đặt',
                  subtitle: 'Thông báo, bảo mật, ngôn ngữ',
                  icon: Icons.settings_outlined,
                  onTap: () => _showMessage(context, 'Mở cài đặt'),
                ),
                _ProfileTile(
                  title: 'Đăng xuất',
                  subtitle: 'Kết thúc phiên đăng nhập',
                  icon: Icons.logout,
                  onTap: _handleSignOut,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.isGuest,
    required this.onEdit,
    required this.onLogin,
    required this.onRegister,
    this.photoBase64,
  });

  final String displayName;
  final String email;
  final String? photoBase64;
  final bool isGuest;
  final VoidCallback onEdit;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (photoBase64 != null && photoBase64!.isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(photoBase64!));
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111111), Color(0xFF3B3B3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: isGuest ? null : onEdit,
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? const Icon(Icons.person, size: 36, color: Colors.black87)
                      : null,
                ),
              ),
              if (!isGuest)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                if (isGuest)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Đăng nhập'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onRegister,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
side: const BorderSide(color: Colors.white54),
                          ),
                          child: const Text('Đăng ký'),
                        ),
                      ),
                    ],
                  )
                else
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Xem thông tin cá nhân'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({
    required this.wishlistCount,
    required this.pendingCount,
    required this.processingCount,
    required this.onCart,
    required this.onPendingConfirm,
    required this.onShipping,
  });

  final String wishlistCount;
  final String pendingCount;
  final String processingCount;
  final VoidCallback onCart;
  final VoidCallback onPendingConfirm;
  final VoidCallback onShipping;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            title: 'Wishlist',
            value: wishlistCount,
            icon: Icons.favorite_border,
            onTap: onCart,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            title: 'Chờ xác nhận',
            value: pendingCount,
            icon: Icons.fact_check_outlined,
            onTap: onPendingConfirm,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            title: 'Chờ giao',
            value: processingCount,
            icon: Icons.local_shipping_outlined,
            onTap: onShipping,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.black87),
const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : Colors.black87;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}