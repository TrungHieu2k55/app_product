import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'cloudinary_config.dart';
import 'data/auth_repository.dart';
import 'data/cloudinary_product_repository.dart';
import 'data/firebase_auth_repository.dart';
import 'data/product_repository.dart';
import 'firebase_options.dart';
import 'models/app_user.dart';
import 'screens/auth_screen.dart';
import 'screens/product_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!DefaultFirebaseOptions.isConfigured || !CloudinaryConfig.isConfigured) {
    runApp(const ProductAdminApp.unconfigured());
    return;
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ProductAdminApp(
      authRepository: FirebaseAuthRepository(FirebaseAuth.instance),
      productRepository: CloudinaryProductRepository(
        FirebaseFirestore.instance,
      ),
    ),
  );
}

class ProductAdminApp extends StatelessWidget {
  const ProductAdminApp({
    super.key,
    required this.authRepository,
    required this.productRepository,
  }) : configured = true;

  const ProductAdminApp.unconfigured({super.key})
    : configured = false,
      authRepository = null,
      productRepository = null;

  final bool configured;
  final AuthRepository? authRepository;
  final ProductRepository? productRepository;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF2563EB);
    ThemeData theme(ColorScheme colors) => ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Product Admin',
      theme: theme(ColorScheme.fromSeed(seedColor: seed)),
      darkTheme: theme(
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      ),
      home: configured
          ? _AuthGate(
              authRepository: authRepository!,
              productRepository: productRepository!,
            )
          : const FirebaseSetupScreen(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate({
    required this.authRepository,
    required this.productRepository,
  });

  final AuthRepository authRepository;
  final ProductRepository productRepository;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  StreamSubscription<AppUser?>? _subscription;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _user = widget.authRepository.currentUser;
    _subscription = widget.authRepository.authChanges.listen((user) {
      if (mounted) setState(() => _user = user);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) {
      return AuthScreen(
        authRepository: widget.authRepository,
        onAuthenticated: (value) => setState(() => _user = value),
      );
    }
    return ProductListScreen(
      user: user,
      repository: widget.productRepository,
      onLogout: () async {
        try {
          await widget.authRepository.signOut();
        } finally {
          if (mounted) setState(() => _user = null);
        }
      },
    );
  }
}

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cần cấu hình Firebase và Cloudinary',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    const SelectableText(
                      'Truyền cấu hình FIREBASE_* và CLOUDINARY_* bằng '
                      '--dart-define. Xem FIREBASE_SETUP.md.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
