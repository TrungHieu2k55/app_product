import '../data/auth_repository.dart';
import '../models/app_user.dart';

abstract interface class AuthView {
  void setAuthLoading(bool loading);
  void showAuthError(String message);
  void onAuthenticated(AppUser user);
}

class AuthPresenter {
  AuthPresenter({required this.repository, required this.view});
  final AuthRepository repository;
  final AuthView view;

  Future<void> login(String email, String password) async {
    view.setAuthLoading(true);
    try {
      final user = await repository.login(email: email, password: password);
      view.onAuthenticated(user);
    } on AuthFailure catch (error) {
      view.showAuthError(error.message);
    } catch (_) {
      view.showAuthError('Không thể đăng nhập. Vui lòng thử lại.');
    } finally {
      view.setAuthLoading(false);
    }
  }

  Future<void> register(String fullName, String email, String password) async {
    view.setAuthLoading(true);
    try {
      final user = await repository.register(
        fullName: fullName,
        email: email,
        password: password,
      );
      view.onAuthenticated(user);
    } on AuthFailure catch (error) {
      view.showAuthError(error.message);
    } catch (_) {
      view.showAuthError('Không thể tạo tài khoản. Vui lòng thử lại.');
    } finally {
      view.setAuthLoading(false);
    }
  }
}
