import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Nên dùng 1 instance GoogleSignIn để quản lý session ổn định
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ======================
  // EMAIL/PASSWORD LOGIN
  // ======================
  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ======================
  // REGISTER + SAVE RTDB
  // ======================
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

    // 2) Lưu RTDB
    final uid = cred.user!.uid;
    await _db.child('users').child(uid).set({
      "fullName": fullName.trim(),
      "email": email.trim(),
      "phone": phone.trim(),
      "address": address.trim(),
      "role": "customer",
      "provider": "password",
      "createdAt": ServerValue.timestamp,
    });

    return cred;
  }

  // ======================
  // GOOGLE SIGN-IN
  // ======================
  Future<UserCredential> signInWithGoogle() async {
    // Nếu muốn luôn hiện màn chọn tài khoản (không auto), có thể signOut trước
    // await _googleSignIn.signOut();

    // 1) Chọn tài khoản Google
    final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
    if (gUser == null) {
      throw Exception("Bạn đã huỷ đăng nhập Google");
    }

    // 2) Lấy token
    final GoogleSignInAuthentication gAuth = await gUser.authentication;

    // 3) Tạo credential cho Firebase
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );

    // 4) Đăng nhập Firebase
    final UserCredential userCred = await _auth.signInWithCredential(credential);

    // 5) Tạo record RTDB nếu chưa có
    final user = userCred.user;
    if (user != null) {
      final uid = user.uid;
      final userRef = _db.child('users').child(uid);
      final snap = await userRef.get();

      if (!snap.exists) {
        await userRef.set({
          "fullName": user.displayName ?? "",
          "email": user.email ?? "",
          "phone": user.phoneNumber ?? "",
          "address": "",
          "role": "customer",
          "provider": "google",
          "createdAt": ServerValue.timestamp,
        });
      } else {
        // (Tuỳ chọn) update lastLogin để bạn theo dõi
        await userRef.update({
          "lastLoginAt": ServerValue.timestamp,
        });
      }
    }

    return userCred;
  }

  // ======================
  // LOGOUT (KHÔNG GHI NHỚ GOOGLE)
  // ======================
  Future<void> logout() async {
    // 1) Logout Firebase trước cũng được, nhưng mình làm Google trước để clear session
    try {
      // disconnect mạnh hơn signOut: xoá liên kết, lần sau bắt chọn account lại
      await _googleSignIn.disconnect();
    } catch (_) {
      // Có thể lỗi nếu chưa từng connect, bỏ qua
    }

    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await _auth.signOut();
  }

  // (Tuỳ chọn) Chỉ logout Google (ít dùng)
  Future<void> signOutGoogleOnly() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
