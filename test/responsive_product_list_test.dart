import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giua_ki/data/product_repository.dart';
import 'package:giua_ki/models/app_user.dart';
import 'package:giua_ki/models/product.dart';
import 'package:giua_ki/screens/product_list_screen.dart';

class ResponsiveRepository implements ProductRepository {
  @override
  Stream<List<Product>> watchAll() => Stream.value(const [
    Product(
      id: 'product-1',
      name: 'Bàn phím cơ',
      price: 1200000,
      soluong: 30,
      image: '',
    ),
  ]);

  @override
  Future<Product> create(
    Product product, {
    Uint8List? imageBytes,
    String imageExtension = 'jpg',
  }) async => product;

  @override
  Future<void> update(
    Product product, {
    Uint8List? imageBytes,
    String imageExtension = 'jpg',
  }) async {}

  @override
  Future<void> delete(Product product) async {}
}

Widget buildScreen() => MaterialApp(
  theme: ThemeData(useMaterial3: true),
  home: ProductListScreen(
    user: const AppUser(
      id: 'admin-1',
      fullName: 'Admin',
      email: 'admin@example.com',
    ),
    repository: ResponsiveRepository(),
    onLogout: () async {},
  ),
);

void main() {
  for (final size in [
    const Size(320, 720),
    const Size(700, 900),
    const Size(1280, 900),
  ]) {
    testWidgets('danh sách không tràn tại ${size.width.toInt()}px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('statsOverview')), findsOneWidget);
      expect(find.text('1.200.000 ₫'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('lọc sản phẩm hết hàng', (tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('stockFilterButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hết hàng'));
    await tester.pumpAndSettle();

    expect(find.text('0 kết quả'), findsOneWidget);
    expect(find.text('Không tìm thấy sản phẩm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chọn sắp xếp theo giá giảm dần', (tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sortButton')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Giá cao → thấp').last);
    await tester.pumpAndSettle();

    expect(find.text('Giá cao → thấp'), findsOneWidget);
    expect(find.text('1.200.000 ₫'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
