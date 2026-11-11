import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<AppUser?> get authChanges =>
      _auth.authStateChanges().map((user) => user == null ? null : _map(user));

  @override
  AppUser? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : _map(user);
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final user = result.user;
      if (user == null) throw const AuthFailure('Đăng nhập thất bại.');
      return _map(user);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_message(error.code));
    }
  }

  @override
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final user = result.user;
      if (user == null) throw const AuthFailure('Đăng ký thất bại.');
      await user.updateDisplayName(fullName.trim());
      await user.reload();
      return _map(_auth.currentUser ?? user);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_message(error.code));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AppUser _map(User user) => AppUser(
    id: user.uid,
    fullName: user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : 'Quản trị viên',
    email: user.email ?? '',
  );

  String _message(String code) => switch (code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Email hoặc mật khẩu không đúng.',
    'email-already-in-use' => 'Email này đã được đăng ký.',
    'weak-password' => 'Mật khẩu phải có ít nhất 6 ký tự.',
    'invalid-email' => 'Email không hợp lệ.',
    'network-request-failed' => 'Không thể kết nối Firebase.',
    'too-many-requests' => 'Thử lại sau ít phút.',
    _ => 'Xác thực thất bại ($code).',
  };
}
