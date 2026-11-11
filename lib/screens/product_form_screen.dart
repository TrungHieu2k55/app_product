import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';

class ProductFormResult {
  const ProductFormResult({
    required this.product,
    this.imageBytes,
    this.imageExtension = 'jpg',
  });

  final Product product;
  final Uint8List? imageBytes;
  final String imageExtension;
}

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _quantity;
  Uint8List? _imageBytes;
  String _imageExtension = 'jpg';
  bool _picking = false;

  bool get _isNew => widget.product == null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _price = TextEditingController(
      text: product == null ? '' : product.price.toStringAsFixed(0),
    );
    _quantity = TextEditingController(text: '${product?.soluong ?? ''}');
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _picking = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ảnh phải nhỏ hơn 5 MB.')),
          );
        }
        return;
      }
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _imageExtension = file.name.split('.').last.toLowerCase();
        });
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final oldImage = widget.product?.image ?? '';
    if (_imageBytes == null && oldImage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn hình ảnh sản phẩm.')),
      );
      return;
    }

    Navigator.pop(
      context,
      ProductFormResult(
        product: Product(
          id: widget.product?.id,
          name: _name.text.trim(),
          price: double.parse(_price.text.trim()),
          soluong: int.parse(_quantity.text.trim()),
          image: oldImage,
        ),
        imageBytes: _imageBytes,
        imageExtension: _imageExtension,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'Thêm sản phẩm' : 'Sửa sản phẩm')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      button: true,
                      label: 'Chọn hình ảnh sản phẩm',
                      child: InkWell(
                        onTap: _picking ? null : _pickImage,
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          height: 240,
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colors.outlineVariant),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(19),
                            child: _imagePreview(colors),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _picking ? null : _pickImage,
                      icon: _picking
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(_imageBytes == null ? 'Chọn ảnh' : 'Đổi ảnh'),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      key: const Key('productNameField'),
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Tên sản phẩm (name)',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Vui lòng nhập tên sản phẩm'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('productPriceField'),
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Giá sản phẩm (price)',
                        prefixIcon: Icon(Icons.payments_outlined),
                        suffixText: '₫',
                      ),
                      validator: (value) {
                        final number = double.tryParse(value?.trim() ?? '');
                        return number == null || number <= 0
                            ? 'Giá phải lớn hơn 0'
                            : null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('productQuantityField'),
                      controller: _quantity,
                      keyboardType: TextInputType.number,
                      onFieldSubmitted: (_) => _save(),
                      decoration: const InputDecoration(
                        labelText: 'Số lượng (soluong)',
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                      validator: (value) {
                        final number = int.tryParse(value?.trim() ?? '');
                        return number == null || number < 0
                            ? 'Số lượng phải từ 0 trở lên'
                            : null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      key: const Key('saveProductButton'),
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(_isNew ? 'Thêm sản phẩm' : 'Lưu thay đổi'),
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

  Widget _imagePreview(ColorScheme colors) {
    if (_imageBytes != null) {
      return Image.memory(_imageBytes!, fit: BoxFit.cover);
    }
    final image = widget.product?.image ?? '';
    if (image.isNotEmpty) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _emptyImage(colors),
      );
    }
    return _emptyImage(colors);
  }

  Widget _emptyImage(ColorScheme colors) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.image_outlined, size: 64, color: colors.primary),
      const SizedBox(height: 8),
      const Text('Nhấn để chọn hình ảnh'),
      const Text('JPG, PNG hoặc WebP • tối đa 5 MB'),
    ],
  );
}
