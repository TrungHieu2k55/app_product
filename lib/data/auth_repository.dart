import '../models/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> get authChanges;
  AppUser? get currentUser;
  Future<AppUser> login({required String email, required String password});
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
  });
  Future<void> signOut();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}
