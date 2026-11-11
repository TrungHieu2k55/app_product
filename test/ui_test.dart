import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giua_ki/main.dart';

void main() {
  testWidgets('màn hình cấu hình không tràn trên điện thoại nhỏ', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ProductAdminApp.unconfigured());
    await tester.pumpAndSettle();
    expect(find.text('Cần cấu hình Firebase và Cloudinary'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('màn hình cấu hình hỗ trợ web rộng', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ProductAdminApp.unconfigured());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
