import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/snack.dart';
import '../../data/models/product.dart';
import '../../providers/auth_controller.dart';
import '../../providers/cart_controller.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/favorites_controller.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/quick_add_button.dart';
import '../../widgets/state_views.dart';
import 'products_screen.dart';

const double _kImageHeight = 300;
const double _kSheetOverlap = 26;

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _qty = 1;
  int _imageIndex = 0;
  bool _expanded = false;
  bool _busy = false;
  int _unitIndex = 0;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productProvider(widget.productId));

    return async.when(
      loading: () => const Scaffold(body: AppLoader()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(productProvider(widget.productId)),
        ),
      ),
      data: (product) {
        final isFav = ref
            .watch(favoritesControllerProvider)
            .contains(product.id);
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  isFav: isFav,
                  onToggleFav: () => ref
                      .read(favoritesControllerProvider.notifier)
                      .toggle(product),
                ),
                Expanded(child: _scrollBody(product)),
              ],
            ),
          ),
          bottomNavigationBar: _BottomBar(
            product: product,
            option: product.saleOptions[_unitIndex.clamp(
              0,
              product.saleOptions.length - 1,
            )],
            qty: _qty,
            busy: _busy,
            isFav: isFav,
            onQtyChanged: (v) => setState(() => _qty = v),
            onAddToCart: () => _addToCart(product),
            onToggleFav: () =>
                ref.read(favoritesControllerProvider.notifier).toggle(product),
          ),
        );
      },
    );
  }

  Widget _scrollBody(Product product) {
    final images = product.images.map((e) => e.url).toList();
    final desc = product.descriptionAr ?? '';
    final options = product.saleOptions;
    final index = _unitIndex.clamp(0, options.length - 1);

    return SingleChildScrollView(
      // The info sheet is lifted over the photo so its rounded top corners cut
      // into the image, which is what gives the reference layout its depth.
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ImageSection(
              images: images,
              height: _kImageHeight,
              index: _imageIndex,
              onPageChanged: (i) => setState(() => _imageIndex = i),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: _kImageHeight - _kSheetOverlap),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category, styled as a link the way the reference shows the brand.
                  if (product.categoryNameAr != null &&
                      product.categoryNameAr!.isNotEmpty)
                    _CategoryLink(
                      name: product.categoryNameAr!,
                      categoryId: product.categoryId,
                    ),
                  const SizedBox(height: 8),
                  // Name
                  Text(
                    product.nameAr,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle (English name or category)
                  if (product.nameEn.isNotEmpty)
                    Text(
                      product.nameEn,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Unit selector (base unit / نص كيلو / كيلو / carton)
                  if (options.length > 1) ...[
                    _UnitSelector(
                      options: options,
                      selected: index,
                      onChanged: (i) => setState(() => _unitIndex = i),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Description
                  if (desc.isNotEmpty)
                    _DescriptionSection(
                      desc: desc,
                      expanded: _expanded,
                      onToggle: () => setState(() => _expanded = !_expanded),
                    ),
                  const SizedBox(height: 20),
                  _RelatedSection(product: product),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart(Product product) async {
    if (!ref.read(authControllerProvider).isAuthenticated) {
      _promptSignIn();
      return;
    }
    final options = product.saleOptions;
    final unit = options[_unitIndex.clamp(0, options.length - 1)].unit;
    setState(() => _busy = true);
    try {
      await ref
          .read(cartControllerProvider.notifier)
          .add(product.id, quantity: _qty, unit: unit);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تمت الإضافة إلى السلة'),
            // A snack bar that carries an action defaults to `persist: true`,
            // so it would hang on the screen until it is tapped.
            persist: false,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'عرض السلة',
              onPressed: () => context.go('/cart'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _promptSignIn() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('يتطلب حساب'),
        content: const Text(
          'يمكنك تصفّح المنتجات بحرية، لكن لإتمام الطلب يجب تسجيل الدخول أو إنشاء حساب.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('لاحقاً'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/login');
            },
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends ConsumerWidget {
  const _TopBar({required this.isFav, required this.onToggleFav});

  final bool isFav;
  final VoidCallback onToggleFav;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartControllerProvider).count;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _CircleBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => context.pop(),
          ),
          const Spacer(),
          _CircleBtn(
            icon: isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? AppColors.danger : Colors.white,
            onTap: onToggleFav,
          ),
          const SizedBox(width: 8),
          _CartBtn(count: count),
        ],
      ),
    );
  }
}

/// Bag button carrying the live cart count, as in the reference header.
class _CartBtn extends StatelessWidget {
  const _CartBtn({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _CircleBtn(
          icon: Icons.shopping_bag_outlined,
          onTap: () => context.push('/cart'),
        ),
        if (count > 0)
          Positioned(
            top: -2,
            left: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.background, width: 1.5),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Category chip above the product name — the reference puts the brand here.
class _CategoryLink extends StatelessWidget {
  const _CategoryLink({required this.name, required this.categoryId});

  final String name;
  final String? categoryId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: categoryId == null
          ? null
          : () => context.push('/products', extra: ProductsArgs(
              categoryId: categoryId,
              title: name,
            )),
      child: Text(
        name,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap, this.color});

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Icon(icon, size: 18, color: color ?? Colors.white),
      ),
    );
  }
}

// ── Image section ─────────────────────────────────────────────────────────────
class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.images,
    required this.height,
    required this.index,
    required this.onPageChanged,
  });

  final List<String> images;
  final double height;
  final int index;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: const Color(0xFFF8F8F8),
      child: images.isEmpty
          ? const Center(
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: AppColors.muted,
              ),
            )
          : Stack(
              children: [
                PageView.builder(
                  itemCount: images.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => _openViewer(context, i),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: CachedNetworkImage(
                        imageUrl: images[i],
                        fit: BoxFit.contain,
                        errorWidget: (_, _, _) => const Icon(
                          Icons.broken_image_outlined,
                          size: 60,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
                // Kept clear of the info sheet that overlaps the image bottom.
                Positioned(
                  bottom: _kSheetOverlap + 10,
                  left: 12,
                  child: GestureDetector(
                    onTap: () => _openViewer(context, index),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Icon(
                        Icons.zoom_out_map_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: _kSheetOverlap + 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == index ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == index
                                ? AppColors.primary
                                : AppColors.muted,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  void _openViewer(BuildContext context, int initialIndex) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            _ImageViewerScreen(images: images, initialIndex: initialIndex),
      ),
    );
  }
}

// ── Fullscreen zoomable image viewer ──────────────────────────────────────────
class _ImageViewerScreen extends StatefulWidget {
  const _ImageViewerScreen({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => _ZoomableImage(url: widget.images[i]),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _CircleBtn(
                icon: Icons.close_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            if (widget.images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_index + 1} / ${widget.images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.url});

  final String url;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final _transform = TransformationController();
  TapDownDetails? _doubleTapAt;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transform.value != Matrix4.identity()) {
      _transform.value = Matrix4.identity();
      return;
    }
    final position = _doubleTapAt?.localPosition;
    if (position == null) return;
    const scale = 2.5;
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        -position.dx * (scale - 1),
        -position.dy * (scale - 1),
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => _doubleTapAt = d,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: widget.url,
            fit: BoxFit.contain,
            errorWidget: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              size: 60,
              color: AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Unit selector ─────────────────────────────────────────────────────────────
class _UnitSelector extends StatelessWidget {
  const _UnitSelector({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<SaleOption> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            _seg(
              label: options[i].label,
              selected: i == selected,
              onTap: () => onChanged(i),
            ),
        ],
      ),
    );
  }

  Widget _seg({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? AppColors.onPrimary : AppColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Price row ─────────────────────────────────────────────────────────────────
class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.product, required this.option});

  final Product product;
  final SaleOption option;

  @override
  Widget build(BuildContext context) {
    final isBaseUnit = option.unit == 'PIECE';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.money(option.price),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '/ ${option.label}',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ),
          ],
        ),
        if (isBaseUnit && product.hasDiscount) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                Formatters.money(product.price),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.muted,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'خصم ${product.discountPercent}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Description section ───────────────────────────────────────────────────────
class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({
    required this.desc,
    required this.expanded,
    required this.onToggle,
  });

  final String desc;
  final bool expanded;
  final VoidCallback onToggle;

  /// Characters kept before the inline «المزيد» link. The reference truncates
  /// mid-sentence and parks the link on the same line, which a plain
  /// `maxLines` + ellipsis cannot do.
  static const int _collapsedLength = 130;

  @override
  Widget build(BuildContext context) {
    final isLong = desc.length > _collapsedLength;
    final shown = expanded || !isLong
        ? desc
        : '${desc.substring(0, _collapsedLength).trimRight()}… ';

    return Text.rich(
      TextSpan(
        text: shown,
        children: [
          if (isLong)
            TextSpan(
              text: expanded ? ' أقل' : 'المزيد',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
              recognizer: TapGestureRecognizer()..onTap = onToggle,
            ),
        ],
      ),
      style: const TextStyle(
        color: AppColors.muted,
        height: 1.7,
        fontSize: 14,
      ),
    );
  }
}

// ── Frequently bought together ────────────────────────────────────────────────
class _RelatedSection extends ConsumerWidget {
  const _RelatedSection({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryId = product.categoryId;
    if (categoryId == null) return const SizedBox.shrink();

    final state = ref.watch(
      productsControllerProvider(ProductQuery(categoryId: categoryId)),
    );
    final items = state.items
        .where((p) => p.id != product.id && !p.isOutOfStock)
        .take(8)
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 20),
        const Text(
          'يُشترى معه عادة',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _RelatedCard(product: items[i]),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _RelatedCard extends ConsumerWidget {
  const _RelatedCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = product.mainImage;
    return GestureDetector(
      // Replace rather than stack, so browsing sideways cannot grow the
      // navigation history one entry per tap.
      onTap: () => context.replace('/product/${product.id}'),
      child: SizedBox(
        width: 124,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 108,
                  width: 124,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: url == null || url.isEmpty
                      ? const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.muted,
                        )
                      : ColoredBox(
                          color: Colors.white,
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                ),
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: QuickAddButton(product: product),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              product.nameAr,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.3,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              Formatters.money(product.effectivePrice),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.product,
    required this.option,
    required this.qty,
    required this.busy,
    required this.isFav,
    required this.onQtyChanged,
    required this.onAddToCart,
    required this.onToggleFav,
  });

  final Product product;
  final SaleOption option;
  final int qty;
  final bool busy;
  final bool isFav;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleFav;

  @override
  Widget build(BuildContext context) {
    final disabled = product.isOutOfStock || busy;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price on one side, quantity on the other — the reference layout.
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(child: _PriceRow(product: product, option: option)),
                  if (!product.isOutOfStock)
                    QuantityStepper(
                      quantity: qty,
                      min: 1,
                      onChanged: onQtyChanged,
                    ),
                ],
              ),
            ),
            // Add to cart + heart
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: disabled ? null : onAddToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.surfaceAlt,
                        disabledForegroundColor: AppColors.muted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.muted,
                              ),
                            )
                          : Text(
                              product.isOutOfStock
                                  ? 'نفذت الكمية'
                                  : 'أضف إلى السلة',
                              style: TextStyle(
                                color: disabled
                                    ? AppColors.muted
                                    : AppColors.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onToggleFav,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? AppColors.danger : AppColors.muted,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
