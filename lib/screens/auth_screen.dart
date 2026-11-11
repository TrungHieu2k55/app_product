import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../models/app_user.dart';
import '../presenters/auth_presenter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.authRepository,
    required this.onAuthenticated,
  });

  final AuthRepository authRepository;
  final ValueChanged<AppUser> onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> implements AuthView {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final AuthPresenter _presenter;
  bool _registerMode = false;
  bool _loading = false;
  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();
    _presenter = AuthPresenter(repository: widget.authRepository, view: this);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_registerMode) {
      _presenter.register(_name.text, _email.text, _password.text);
    } else {
      _presenter.login(_email.text, _password.text);
    }
  }

  @override
  void setAuthLoading(bool loading) {
    if (mounted) setState(() => _loading = loading);
  }

  @override
  void showAuthError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  void onAuthenticated(AppUser user) => widget.onAuthenticated(user);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.inventory_2_rounded,
                      size: 72,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Product Admin',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _registerMode
                          ? 'Tạo tài khoản quản trị Firebase'
                          : 'Đăng nhập để quản lý sản phẩm',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    if (_registerMode) ...[
                      TextFormField(
                        key: const Key('registerNameField'),
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 2
                            ? 'Vui lòng nhập họ tên'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      key: const Key('authEmailField'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (value) => value != null && value.contains('@')
                          ? null
                          : 'Email không hợp lệ',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('authPasswordField'),
                      controller: _password,
                      obscureText: _hidePassword,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _hidePassword
                              ? 'Hiện mật khẩu'
                              : 'Ẩn mật khẩu',
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'Mật khẩu tối thiểu 6 ký tự'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('authSubmitButton'),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_registerMode ? 'Đăng ký' : 'Đăng nhập'),
                    ),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () =>
                                setState(() => _registerMode = !_registerMode),
                      child: Text(
                        _registerMode
                            ? 'Đã có tài khoản? Đăng nhập'
                            : 'Chưa có tài khoản? Đăng ký ngay',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
