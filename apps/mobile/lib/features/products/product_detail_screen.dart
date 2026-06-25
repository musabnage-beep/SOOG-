import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/product.dart';
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
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productProvider(widget.productId));

    return Scaffold(
      body: async.when(
        loading: () => const AppLoader(),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(productProvider(widget.productId)),
          ),
        ),
        data: (product) => _content(product),
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (product) => _bottomBar(product),
        orElse: () => null,
      ),
    );
  }

  Widget _content(Product product) {
    final images = product.images.map((e) => e.url).toList();
    final isFav = ref.watch(favoritesControllerProvider).contains(product.id);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: AppColors.surface,
          actions: [
            IconButton(
              onPressed: () =>
                  ref.read(favoritesControllerProvider.notifier).toggle(product),
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? AppColors.danger : AppColors.dark,
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: AppColors.cream,
              child: images.isEmpty
                  ? const Center(
                      child: Icon(Icons.shopping_bag_outlined,
                          size: 80, color: AppColors.muted),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            itemCount: images.length,
                            onPageChanged: (i) => setState(() => _imageIndex = i),
                            itemBuilder: (_, i) => CachedNetworkImage(
                              imageUrl: images[i],
                              fit: BoxFit.contain,
                              errorWidget: (_, _, _) =>
                                  const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                        if (images.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                images.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: i == _imageIndex ? 18 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: i == _imageIndex
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
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.categoryNameAr != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(product.categoryNameAr!,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(height: 12),
                Text(
                  product.nameAr,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      Formatters.money(product.effectivePrice),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (product.hasDiscount)
                      Text(
                        Formatters.money(product.price),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _StockBadge(status: product.stockStatus),
                const SizedBox(height: 20),
                if ((product.descriptionAr ?? '').isNotEmpty) ...[
                  const Text('الوصف',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    product.descriptionAr!,
                    style: const TextStyle(color: AppColors.muted, height: 1.6),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(Product product) {
    final disabled = product.isOutOfStock || _busy;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            if (!product.isOutOfStock)
              QuantityStepper(
                quantity: _qty,
                min: 1,
                onChanged: (v) => setState(() => _qty = v),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: disabled ? null : () => _addToCart(product),
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add_shopping_cart),
                label: Text(product.isOutOfStock ? 'نفذت الكمية' : 'أضف إلى السلة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(Product product) async {
    setState(() => _busy = true);
    try {
      await ref.read(cartControllerProvider.notifier).add(product.id, quantity: _qty);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تمت الإضافة إلى السلة'),
            action: SnackBarAction(
              label: 'عرض السلة',
              onPressed: () => context.go('/cart'),
            ),
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
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.status});

  final StockStatus status;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    switch (status) {
      case StockStatus.inStock:
        label = 'متوفر';
        color = AppColors.success;
        break;
      case StockStatus.lowStock:
        label = 'كمية محدودة';
        color = AppColors.warning;
        break;
      case StockStatus.outOfStock:
        label = 'نفذت الكمية';
        color = AppColors.danger;
        break;
      case StockStatus.unknown:
        return const SizedBox.shrink();
    }
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
