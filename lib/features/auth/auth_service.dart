import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  /// Đăng nhập email/password
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Đăng ký tài khoản
  Future<UserCredential> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;

    await _db.child('users').child(uid).set({
      "fullName": fullName.trim(),
      "email": email.trim(),
      "phone": phone.trim(),
      "address": address.trim(),
      "role": "customer",
      "createdAt": ServerValue.timestamp,
    });

    return cred;
  }

  /// Đăng nhập Google
  Future<UserCredential?> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _auth.signInWithCredential(credential);

      // Lưu user nếu chưa có trong Realtime DB
      final uid = userCredential.user!.uid;
      final snapshot = await _db.child('users').child(uid).get();
      if (!snapshot.exists) {
        await _db.child('users').child(uid).set({
          "fullName": userCredential.user!.displayName ?? "Google User",
          "email": userCredential.user!.email ?? "",
          "phone": "",
          "address": "",
          "role": "customer",
          "createdAt": ServerValue.timestamp,
        });
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
