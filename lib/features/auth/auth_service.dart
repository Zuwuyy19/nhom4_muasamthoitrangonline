import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  // ✅ NEW: Google Sign-In
  Future<UserCredential> signInWithGoogle() async {
    // 1) chọn tài khoản google
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
    if (gUser == null) {
      throw Exception("Bạn đã huỷ đăng nhập Google");
    }

    // 2) lấy token
    final gAuth = await gUser.authentication;

    // 3) tạo credential cho Firebase
    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );

    // 4) sign-in firebase
    final userCred = await _auth.signInWithCredential(credential);

    // 5) (tuỳ chọn nhưng nên làm) tạo user record trên RTDB nếu chưa có
    final user = userCred.user;
    if (user != null) {
      final uid = user.uid;
      final snap = await _db.child('users').child(uid).get();

      if (!snap.exists) {
        await _db.child('users').child(uid).set({
          "fullName": user.displayName ?? "",
          "email": user.email ?? "",
          "phone": user.phoneNumber ?? "",
          "address": "",
          "role": "customer",
          "provider": "google",
          "createdAt": ServerValue.timestamp,
        });
      }
    }

    return userCred;
  }

  Future<void> logout() async {
    await GoogleSignIn().signOut(); // để lần sau không auto chọn tài khoản cũ
    await _auth.signOut();
  }
}