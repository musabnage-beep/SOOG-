import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/product.dart';
import '../../providers/auth_controller.dart';
import '../../providers/cart_controller.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/favorites_controller.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/state_views.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _qty = 1;
  int _imageIndex = 0;
  bool _expanded = false;
  bool _busy = false;

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
        final isFav = ref.watch(favoritesControllerProvider).contains(product.id);
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  isFav: isFav,
                  onToggleFav: () =>
                      ref.read(favoritesControllerProvider.notifier).toggle(product),
                ),
                Expanded(child: _scrollBody(product)),
              ],
            ),
          ),
          bottomNavigationBar: _BottomBar(
            product: product,
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image carousel ──────────────────────────────────────────
          _ImageSection(
            images: images,
            index: _imageIndex,
            onPageChanged: (i) => setState(() => _imageIndex = i),
          ),

          // ── Info ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  product.nameAr,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
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
                // Price row
                _PriceRow(product: product),
                const SizedBox(height: 24),
                // Description
                if (desc.isNotEmpty) _DescriptionSection(desc: desc, expanded: _expanded, onToggle: () => setState(() => _expanded = !_expanded)),
                const SizedBox(height: 20),
              ],
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
    setState(() => _busy = true);
    try {
      await ref.read(cartControllerProvider.notifier).add(product.id, quantity: _qty);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تمت الإضافة إلى السلة'),
            action: SnackBarAction(label: 'عرض السلة', onPressed: () => context.go('/cart')),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
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
            'يمكنك تصفّح المنتجات بحرية، لكن لإتمام الطلب يجب تسجيل الدخول أو إنشاء حساب.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لاحقاً')),
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
class _TopBar extends StatelessWidget {
  const _TopBar({required this.isFav, required this.onToggleFav});

  final bool isFav;
  final VoidCallback onToggleFav;

  @override
  Widget build(BuildContext context) {
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
            icon: Icons.share_outlined,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _CircleBtn(
            icon: isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? AppColors.danger : AppColors.dark,
            onTap: onToggleFav,
          ),
        ],
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
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, size: 18, color: color ?? AppColors.dark),
      ),
    );
  }
}

// ── Image section ─────────────────────────────────────────────────────────────
class _ImageSection extends StatelessWidget {
  const _ImageSection({required this.images, required this.index, required this.onPageChanged});

  final List<String> images;
  final int index;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      color: const Color(0xFFF8F8F8),
      child: images.isEmpty
          ? const Center(child: Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.muted))
          : Stack(
              children: [
                PageView.builder(
                  itemCount: images.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: CachedNetworkImage(
                      imageUrl: images[i],
                      fit: BoxFit.contain,
                      errorWidget: (_, _, _) =>
                          const Icon(Icons.broken_image_outlined, size: 60, color: AppColors.muted),
                    ),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 12,
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
                            color: i == index ? AppColors.primary : AppColors.muted,
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
}

// ── Price row ─────────────────────────────────────────────────────────────────
class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.money(product.effectivePrice),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
        if (product.hasDiscount) ...[
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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

  @override
  Widget build(BuildContext context) {
    const maxLines = 3;
    final isLong = desc.length > 120;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'وصف المنتج',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.dark),
        ),
        const SizedBox(height: 10),
        Text(
          desc,
          maxLines: expanded ? null : maxLines,
          overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.muted,
            height: 1.7,
            fontSize: 14,
          ),
        ),
        if (isLong) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onToggle,
            child: Text(
              expanded ? 'اقرأ أقل' : 'اقرأ المزيد',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.product,
    required this.qty,
    required this.busy,
    required this.isFav,
    required this.onQtyChanged,
    required this.onAddToCart,
    required this.onToggleFav,
  });

  final Product product;
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
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quantity stepper row
            if (!product.isOutOfStock)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                        disabledBackgroundColor: AppColors.muted.withOpacity(0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(
                              product.isOutOfStock ? 'نفذت الكمية' : 'أضف إلى السلة',
                              style: const TextStyle(
                                color: Colors.white,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
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
