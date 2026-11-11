import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:giua_ki/data/product_repository.dart';
import 'package:giua_ki/models/product.dart';
import 'package:giua_ki/presenters/product_presenter.dart';

class MemoryProductRepository implements ProductRepository {
  final _controller = StreamController<List<Product>>.broadcast();
  final items = <Product>[];

  void emit() => _controller.add(List.unmodifiable(items));

  @override
  Stream<List<Product>> watchAll() => _controller.stream;

  @override
  Future<Product> create(
    Product product, {
    Uint8List? imageBytes,
    String imageExtension = 'jpg',
  }) async {
    final created = product.copyWith(id: 'product-1', image: 'image-url');
    items.add(created);
    emit();
    return created;
  }

  @override
  Future<void> update(
    Product product, {
    Uint8List? imageBytes,
    String imageExtension = 'jpg',
  }) async {
    items[items.indexWhere((item) => item.id == product.id)] = product;
    emit();
  }

  @override
  Future<void> delete(Product product) async {
    items.removeWhere((item) => item.id == product.id);
    emit();
  }

  Future<void> dispose() => _controller.close();
}

class FakeProductView implements ProductView {
  List<Product> products = [];
  String? error;
  String? message;
  bool loading = false;

  @override
  void showProductError(String message) => error = message;
  @override
  void showProductMessage(String message) => this.message = message;
  @override
  void showProducts(List<Product> products) => this.products = products;
  @override
  void showProductsLoading(bool loading) => this.loading = loading;
}

void main() {
  test('Product chỉ xuất đúng bốn trường yêu cầu', () {
    const product = Product(
      name: 'Chuột không dây',
      price: 350000,
      soluong: 8,
      image: 'https://example.com/image.jpg',
    );
    expect(product.toMap().keys, ['name', 'price', 'soluong', 'image']);
  });

  test('Presenter thực hiện thêm, sửa, xóa sản phẩm', () async {
    final repository = MemoryProductRepository();
    final view = FakeProductView();
    final presenter = ProductPresenter(repository: repository, view: view);
    presenter.start();

    const draft = Product(
      name: 'Bàn phím cơ',
      price: 890000,
      soluong: 12,
      image: '',
    );
    await presenter.save(draft, isNew: true, imageBytes: Uint8List(4));
    await Future<void>.delayed(Duration.zero);
    expect(view.products, hasLength(1));

    final updated = view.products.single.copyWith(soluong: 20);
    await presenter.save(updated, isNew: false);
    await Future<void>.delayed(Duration.zero);
    expect(view.products.single.soluong, 20);

    await presenter.delete(updated);
    await Future<void>.delayed(Duration.zero);
    expect(view.products, isEmpty);

    await presenter.dispose();
    await repository.dispose();
  });
}
