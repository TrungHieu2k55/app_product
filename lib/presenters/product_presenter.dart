import 'dart:async';
import 'dart:typed_data';

import '../data/product_repository.dart';
import '../models/product.dart';

abstract interface class ProductView {
  void showProducts(List<Product> products);
  void showProductsLoading(bool loading);
  void showProductError(String message);
  void showProductMessage(String message);
}

class ProductPresenter {
  ProductPresenter({required this.repository, required this.view});

  final ProductRepository repository;
  final ProductView view;
  StreamSubscription<List<Product>>? _subscription;

  void start() {
    view.showProductsLoading(true);
    _subscription = repository.watchAll().listen(
      (products) {
        view.showProducts(products);
        view.showProductsLoading(false);
      },
      onError: (Object error) {
        view.showProductError('Không thể tải sản phẩm: $error');
        view.showProductsLoading(false);
      },
    );
  }

  Future<void> save(
    Product product, {
    required bool isNew,
    Uint8List? imageBytes,
    String imageExtension = 'jpg',
  }) async {
    try {
      if (isNew) {
        await repository.create(
          product,
          imageBytes: imageBytes,
          imageExtension: imageExtension,
        );
      } else {
        await repository.update(
          product,
          imageBytes: imageBytes,
          imageExtension: imageExtension,
        );
      }
      view.showProductMessage(
        isNew ? 'Đã thêm sản phẩm.' : 'Đã cập nhật sản phẩm.',
      );
    } catch (error) {
      view.showProductError('Không thể lưu sản phẩm: $error');
    }
  }

  Future<void> delete(Product product) async {
    try {
      await repository.delete(product);
      view.showProductMessage('Đã xóa ${product.name}.');
    } catch (error) {
      view.showProductError('Không thể xóa sản phẩm: $error');
    }
  }

  Future<void> dispose() async => _subscription?.cancel();
}
