import 'package:flutter/material.dart';

import '../data/product_repository.dart';
import '../models/app_user.dart';
import '../models/product.dart';
import '../presenters/product_presenter.dart';
import 'product_form_screen.dart';

enum _StockFilter { all, inStock, lowStock, outOfStock }

enum _ProductSort { nameAsc, priceAsc, priceDesc, quantityAsc, quantityDesc }

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({
    super.key,
    required this.user,
    required this.repository,
    required this.onLogout,
  });

  final AppUser user;
  final ProductRepository repository;
  final Future<void> Function() onLogout;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen>
    implements ProductView {
  final _search = TextEditingController();
  late final ProductPresenter _presenter;
  List<Product> _products = [];
  bool _loading = true;
  bool _loggingOut = false;
  String? _error;
  _StockFilter _stockFilter = _StockFilter.all;
  _ProductSort _sort = _ProductSort.nameAsc;

  List<Product> get _filtered {
    final query = _search.text.trim().toLowerCase();
    final items = _products.where((product) {
      final matchesQuery =
          query.isEmpty || product.name.toLowerCase().contains(query);
      final matchesStock = switch (_stockFilter) {
        _StockFilter.all => true,
        _StockFilter.inStock => product.soluong > 0,
        _StockFilter.lowStock => product.soluong > 0 && product.soluong <= 10,
        _StockFilter.outOfStock => product.soluong == 0,
      };
      return matchesQuery && matchesStock;
    }).toList();

    items.sort(switch (_sort) {
      _ProductSort.nameAsc => (a, b) => a.name.toLowerCase().compareTo(
        b.name.toLowerCase(),
      ),
      _ProductSort.priceAsc => (a, b) => a.price.compareTo(b.price),
      _ProductSort.priceDesc => (a, b) => b.price.compareTo(a.price),
      _ProductSort.quantityAsc => (a, b) => a.soluong.compareTo(b.soluong),
      _ProductSort.quantityDesc => (a, b) => b.soluong.compareTo(a.soluong),
    });
    return items;
  }

  String get _stockFilterLabel => switch (_stockFilter) {
    _StockFilter.all => 'Tất cả tồn kho',
    _StockFilter.inStock => 'Còn hàng',
    _StockFilter.lowStock => 'Sắp hết hàng',
    _StockFilter.outOfStock => 'Hết hàng',
  };

  String get _sortLabel => switch (_sort) {
    _ProductSort.nameAsc => 'Tên A → Z',
    _ProductSort.priceAsc => 'Giá thấp → cao',
    _ProductSort.priceDesc => 'Giá cao → thấp',
    _ProductSort.quantityAsc => 'Số lượng tăng dần',
    _ProductSort.quantityDesc => 'Số lượng giảm dần',
  };

  @override
  void initState() {
    super.initState();
    _presenter = ProductPresenter(repository: widget.repository, view: this);
    _presenter.start();
  }

  @override
  void dispose() {
    _presenter.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  void showProducts(List<Product> products) {
    if (mounted) setState(() => _products = products);
  }

  @override
  void showProductsLoading(bool loading) {
    if (mounted) setState(() => _loading = loading);
  }

  @override
  void showProductError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  void showProductMessage(String message) {
    if (!mounted) return;
    setState(() => _error = null);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openForm([Product? product]) async {
    final result = await Navigator.push<ProductFormResult>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (result == null) return;
    await _presenter.save(
      result.product,
      isNew: product == null,
      imageBytes: result.imageBytes,
      imageExtension: result.imageExtension,
    );
  }

  Future<void> _delete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Xóa sản phẩm?'),
        content: Text('“${product.name}” sẽ bị xóa khỏi Firebase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _presenter.delete(product);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: Text('Đăng xuất khỏi ${widget.user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _loggingOut = true);
    await widget.onLogout();
  }

  String _money(double value) =>
      '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (_) => '.')} ₫';

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final totalUnits = _products.fold<int>(
      0,
      (sum, item) => sum + item.soluong,
    );
    final inventoryValue = _products.fold<double>(
      0,
      (sum, item) => sum + item.price * item.soluong,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('Product Admin')],
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: _loggingOut ? null : _logout,
            icon: _loggingOut
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addProductButton'),
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm sản phẩm'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth > 1440
                ? (constraints.maxWidth - 1400) / 2 + 20
                : 20.0;
            final columns = constraints.maxWidth >= 1200
                ? 4
                : constraints.maxWidth >= 820
                ? 3
                : constraints.maxWidth >= 560
                ? 2
                : 1;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      20,
                      horizontalPadding,
                      20,
                    ),
                    child: Column(
                      children: [
                        _StatsOverview(
                          productCount: _products.length,
                          totalUnits: totalUnits,
                          inventoryValue: _money(inventoryValue),
                        ),
                        const SizedBox(height: 16),
                        SearchBar(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          hintText: 'Tìm theo tên sản phẩm',
                          leading: const Icon(Icons.search),
                          trailing: _search.text.isEmpty
                              ? null
                              : [
                                  IconButton(
                                    tooltip: 'Xóa tìm kiếm',
                                    onPressed: () {
                                      _search.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                        ),
                        const SizedBox(height: 12),
                        _ProductsToolbar(
                          resultCount: items.length,
                          stockFilter: _stockFilter,
                          stockFilterLabel: _stockFilterLabel,
                          sort: _sort,
                          sortLabel: _sortLabel,
                          onStockFilterChanged: (value) {
                            setState(() => _stockFilter = value);
                          },
                          onSortChanged: (value) {
                            setState(() => _sort = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null && _products.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Empty(
                      icon: Icons.cloud_off_outlined,
                      title: 'Không thể tải dữ liệu',
                      message: _error!,
                    ),
                  )
                else if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Empty(
                      icon: Icons.inventory_2_outlined,
                      title:
                          _search.text.isEmpty &&
                              _stockFilter == _StockFilter.all
                          ? 'Chưa có sản phẩm'
                          : 'Không tìm thấy sản phẩm',
                      message:
                          _search.text.isEmpty &&
                              _stockFilter == _StockFilter.all
                          ? 'Nhấn “Thêm sản phẩm” để nhập dữ liệu đầu tiên.'
                          : 'Hãy thử từ khóa hoặc bộ lọc khác.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      100,
                    ),
                    sliver: SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: columns == 1 ? 164 : 330,
                      ),
                      itemCount: items.length,
                      itemBuilder: (_, index) => _ProductCard(
                        product: items[index],
                        money: _money,
                        compact: columns == 1,
                        onEdit: () => _openForm(items[index]),
                        onDelete: () => _delete(items[index]),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.money,
    required this.compact,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final String Function(double) money;
  final bool compact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactCard(context);
    }

    final image = AspectRatio(
      aspectRatio: 16 / 10,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: _interactiveProductImage(context),
      ),
    );
    final details = Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text(
              money(product.price),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text('Số lượng: ${product.soluong}'),
          ],
        ),
      ),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          compact
              ? Row(
                  children: [
                    SizedBox(width: 150, child: image),
                    details,
                  ],
                )
              : Column(children: [image, details]),
          Positioned(top: 6, right: 6, child: _menuButton(context)),
        ],
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageSize = constraints.maxWidth < 340 ? 104.0 : 120.0;

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: imageSize,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _interactiveProductImage(context),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Transform.translate(
                            offset: const Offset(8, -8),
                            child: _menuButton(context, transparent: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        money(product.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      _StockBadge(quantity: product.soluong),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _productImage() {
    if (product.image.isEmpty) {
      return const ColoredBox(
        color: Color(0xFFE2E8F0),
        child: Icon(Icons.image_outlined, size: 42),
      );
    }

    return Image.network(
      product.image,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFFE2E8F0),
        child: Icon(Icons.broken_image_outlined, size: 42),
      ),
    );
  }

  Widget _interactiveProductImage(BuildContext context) {
    if (product.image.isEmpty) return _productImage();
    final heroTag = 'product-image-${product.id}';

    return Semantics(
      button: true,
      label: 'Xem ảnh ${product.name} toàn màn hình',
      child: Tooltip(
        message: 'Nhấn để xem ảnh',
        child: InkWell(
          key: Key('productImage-${product.id}'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _ImagePreviewScreen(
                  imageUrl: product.image,
                  productName: product.name,
                  heroTag: heroTag,
                ),
              ),
            );
          },
          child: Hero(tag: heroTag, child: _productImage()),
        ),
      ),
    );
  }

  Widget _menuButton(BuildContext context, {bool transparent = false}) {
    return Material(
      color: transparent
          ? Colors.transparent
          : Theme.of(context).colorScheme.surface.withAlpha(230),
      borderRadius: BorderRadius.circular(24),
      child: PopupMenuButton<String>(
        tooltip: 'Tùy chọn sản phẩm',
        onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Sửa'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text('Xóa'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsToolbar extends StatelessWidget {
  const _ProductsToolbar({
    required this.resultCount,
    required this.stockFilter,
    required this.stockFilterLabel,
    required this.sort,
    required this.sortLabel,
    required this.onStockFilterChanged,
    required this.onSortChanged,
  });

  final int resultCount;
  final _StockFilter stockFilter;
  final String stockFilterLabel;
  final _ProductSort sort;
  final String sortLabel;
  final ValueChanged<_StockFilter> onStockFilterChanged;
  final ValueChanged<_ProductSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final filterButton = PopupMenuButton<_StockFilter>(
      key: const Key('stockFilterButton'),
      tooltip: 'Lọc theo tồn kho',
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      initialValue: stockFilter,
      onSelected: onStockFilterChanged,
      itemBuilder: (_) => _StockFilter.values
          .map(
            (value) => PopupMenuItem(
              value: value,
              child: _CheckedMenuLabel(
                selected: value == stockFilter,
                label: switch (value) {
                  _StockFilter.all => 'Tất cả tồn kho',
                  _StockFilter.inStock => 'Còn hàng',
                  _StockFilter.lowStock => 'Sắp hết hàng (≤ 10)',
                  _StockFilter.outOfStock => 'Hết hàng',
                },
              ),
            ),
          )
          .toList(),
      child: _ToolbarButton(
        icon: Icons.filter_alt_outlined,
        label: stockFilterLabel,
        active: stockFilter != _StockFilter.all,
      ),
    );
    final sortButton = PopupMenuButton<_ProductSort>(
      key: const Key('sortButton'),
      tooltip: 'Sắp xếp sản phẩm',
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 300),
      initialValue: sort,
      onSelected: onSortChanged,
      itemBuilder: (_) => _ProductSort.values
          .map(
            (value) => PopupMenuItem(
              value: value,
              child: _CheckedMenuLabel(
                selected: value == sort,
                label: switch (value) {
                  _ProductSort.nameAsc => 'Tên A → Z',
                  _ProductSort.priceAsc => 'Giá thấp → cao',
                  _ProductSort.priceDesc => 'Giá cao → thấp',
                  _ProductSort.quantityAsc => 'Số lượng tăng dần',
                  _ProductSort.quantityDesc => 'Số lượng giảm dần',
                },
              ),
            ),
          )
          .toList(),
      child: _ToolbarButton(
        icon: Icons.swap_vert_rounded,
        label: sortLabel,
        active: sort != _ProductSort.nameAsc,
      ),
    );
    final resultLabel = Text(
      '$resultCount kết quả',
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.centerRight, child: resultLabel),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: filterButton),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: sortButton),
            ],
          );
        }

        return Row(
          children: [
            filterButton,
            const SizedBox(width: 8),
            sortButton,
            const Spacer(),
            resultLabel,
          ],
        );
      },
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: active ? colors.primaryContainer : colors.surface,
        border: Border.all(
          color: active ? colors.primary : colors.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down_rounded),
        ],
      ),
    );
  }
}

class _CheckedMenuLabel extends StatelessWidget {
  const _CheckedMenuLabel({required this.selected, required this.label});

  final bool selected;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: selected
              ? Icon(
                  Icons.check_rounded,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
        ),
        Expanded(child: Text(label)),
      ],
    );
  }
}

class _ImagePreviewScreen extends StatelessWidget {
  const _ImagePreviewScreen({
    required this.imageUrl,
    required this.productName,
    required this.heroTag,
  });

  final String imageUrl;
  final String productName;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(productName, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            label: 'Ảnh toàn màn hình của $productName',
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(80),
              child: Center(
                child: Hero(
                  tag: heroTag,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white70,
                          size: 64,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Không thể tải ảnh',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xB3000000),
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      'Kéo hoặc chụm để phóng to ảnh',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.quantity});

  final int quantity;

  @override
  Widget build(BuildContext context) {
    final available = quantity > 0;
    final background = available
        ? const Color(0xFFE8F5EC)
        : Theme.of(context).colorScheme.errorContainer;
    final foreground = available
        ? const Color(0xFF237A3B)
        : Theme.of(context).colorScheme.onErrorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            available ? Icons.inventory_2_outlined : Icons.error_outline,
            size: 16,
            color: foreground,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              available ? 'Còn $quantity sản phẩm' : 'Hết hàng',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 92),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StatsOverview extends StatelessWidget {
  const _StatsOverview({
    required this.productCount,
    required this.totalUnits,
    required this.inventoryValue,
  });

  final int productCount;
  final int totalUnits;
  final String inventoryValue;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _Stat(
        label: 'Sản phẩm',
        value: '$productCount',
        icon: Icons.inventory_2_outlined,
      ),
      _Stat(
        label: 'Tổng số lượng',
        value: '$totalUnits',
        icon: Icons.numbers_rounded,
      ),
      _Stat(
        label: 'Giá trị kho',
        value: inventoryValue,
        icon: Icons.payments_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            key: const Key('statsOverview'),
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                if (index > 0) const SizedBox(width: 12),
                Expanded(child: cards[index]),
              ],
            ],
          );
        }

        if (constraints.maxWidth >= 560) {
          return Column(
            key: const Key('statsOverview'),
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: cards[2]),
            ],
          );
        }

        return Column(
          key: const Key('statsOverview'),
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              if (index > 0) const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: cards[index]),
            ],
          ],
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
