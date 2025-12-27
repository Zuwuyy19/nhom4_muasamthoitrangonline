import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    // 1) Tạo user trong FirebaseAuth
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;

    // 2) Lưu thông tin user vào Realtime Database: users/{uid}
    await _db.child('users').child(uid).set({
      "fullName": fullName.trim(),
      "email": email.trim(),
      "phone": phone.trim(),
      "address": address.trim(),
      "role": "customer",
      "createdAt": ServerValue.timestamp, // ✅ timestamp cho RTDB
    });

    return cred;
  }

  Future<void> logout() => _auth.signOut();
}
