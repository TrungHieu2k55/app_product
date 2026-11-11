import 'dart:typed_data';

import '../models/product.dart';

abstract interface class ProductRepository {
  Stream<List<Product>> watchAll();

  Future<Product> create(
    Product product, {
    Uint8List? imageBytes,
    String imageExtension = 'jpg',
  });

  Future<void> update(
    Product product, {
    Uint8List? imageBytes,
    String imageExtension = 'jpg',
  });

  Future<void> delete(Product product);
}
