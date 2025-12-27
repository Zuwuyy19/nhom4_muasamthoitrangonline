import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _required(String? v, String fieldName) {
    if (v == null || v.trim().isEmpty) return "Vui lòng nhập $fieldName";
    return null;
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return "Vui lòng nhập email";
    final ok = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$").hasMatch(v.trim());
    if (!ok) return "Email không hợp lệ";
    return null;
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.isEmpty) return "Vui lòng nhập mật khẩu";
    if (v.length < 6) return "Mật khẩu tối thiểu 6 ký tự";
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mật khẩu xác nhận không khớp")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _authService.register(
        fullName: _fullNameCtrl.text,
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        phone: _phoneCtrl.text,
        address: _addressCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng ký thành công!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        "email-already-in-use" => "Email đã được sử dụng",
        "invalid-email" => "Email không hợp lệ",
        "weak-password" => "Mật khẩu quá yếu",
        _ => "Đăng ký thất bại: ${e.message ?? e.code}",
      };

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _decor(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: _decor("Họ và tên", icon: Icons.person),
                  validator: (v) => _required(v, "họ và tên"),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: _decor("Email", icon: Icons.email),
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: _decor("Số điện thoại", icon: Icons.phone),
                  validator: (v) => _required(v, "số điện thoại"),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: _decor("Địa chỉ", icon: Icons.location_on),
                  validator: (v) => _required(v, "địa chỉ"),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: _decor("Mật khẩu", icon: Icons.lock).copyWith(
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                  obscureText: _obscure,
                  validator: _passwordValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmCtrl,
                  decoration: _decor("Nhập lại mật khẩu", icon: Icons.lock_outline),
                  obscureText: _obscure,
                  validator: _passwordValidator,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleRegister,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Tạo tài khoản"),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          ),
                  child: const Text("Đã có tài khoản? Đăng nhập"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
