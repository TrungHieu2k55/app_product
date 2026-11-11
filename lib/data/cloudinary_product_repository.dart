import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../cloudinary_config.dart';
import '../models/product.dart';
import 'product_repository.dart';

class CloudinaryProductRepository implements ProductRepository {
  CloudinaryProductRepository(this._firestore, {http.Client? client})
    : _client = client ?? http.Client();

  final FirebaseFirestore _firestore;
  final http.Client _client;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  @override
  Stream<List<Product>> watchAll() => _products.snapshots().map((snapshot) {
    final items = snapshot.docs
        .map((doc) => Product.fromMap(doc.id, doc.data()))
        .toList();
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  });

  @override
  Future<Product> create(
    Product product, {
    Uint8List? imageBytes,
    String imageExtension = 'jpg',
  }) async {
    final document = _products.doc();
    final image = imageBytes == null
        ? product.image
        : await _upload(document.id, imageBytes, imageExtension);
    final created = product.copyWith(id: document.id, image: image);
    await document.set(created.toMap());
    return created;
  }

  @override
  Future<void> update(
    Product product, {
    Uint8List? imageBytes,
    String imageExtension = 'jpg',
  }) async {
    final id = product.id;
    if (id == null) throw StateError('Sản phẩm chưa có id.');
    final image = imageBytes == null
        ? product.image
        : await _upload(id, imageBytes, imageExtension);
    await _products.doc(id).update(product.copyWith(image: image).toMap());
  }

  @override
  Future<void> delete(Product product) async {
    final id = product.id;
    if (id != null) await _products.doc(id).delete();
  }

  Future<String> _upload(
    String productId,
    Uint8List bytes,
    String extension,
  ) async {
    if (!CloudinaryConfig.isConfigured) {
      throw StateError('Chưa cấu hình Cloudinary cloud name/upload preset.');
    }

    final safeExtension = extension.toLowerCase().replaceAll('.', '');
    final uploadId = '${productId}_${DateTime.now().millisecondsSinceEpoch}';
    final request = http.MultipartRequest('POST', CloudinaryConfig.uploadUri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = 'product_admin'
      ..fields['public_id'] = uploadId
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'product.$safeExtension',
        ),
      );

    final response = await _client.send(request);
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = json['error'] as Map<String, dynamic>?;
      throw StateError(error?['message']?.toString() ?? 'Upload ảnh thất bại.');
    }

    final secureUrl = json['secure_url']?.toString();
    if (secureUrl == null || secureUrl.isEmpty) {
      throw StateError('Cloudinary không trả về secure_url.');
    }
    return secureUrl;
  }
}
