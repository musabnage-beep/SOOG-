import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/category.dart';
import '../../providers/cart_controller.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/notifications_controller.dart';
import '../../widgets/app_asset.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/product_card.dart';
import '../../widgets/state_views.dart';
import '../products/products_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final products = ref.watch(productsControllerProvider(const ProductQuery()));
    final cartCount = ref.watch(cartControllerProvider).count;
    final unread = ref.watch(notificationsControllerProvider).unreadCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(categoriesProvider);
            await ref
                .read(productsControllerProvider(const ProductQuery()).notifier)
                .refresh();
          },
          child: CustomScrollView(
            slivers: [
              // ── Top bar ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _TopBar(cartCount: cartCount, unread: unread),
              ),
              // ── Delivery location ────────────────────────────────────────
              const SliverToBoxAdapter(child: _DeliveryRow()),
              // ── Search bar ───────────────────────────────────────────────
              const SliverToBoxAdapter(child: _SearchBar()),
              // ── Hero banner ──────────────────────────────────────────────
              const SliverToBoxAdapter(child: _HeroBanner()),
              // ── Categories section ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/categories'),
                        child: const Text(
                          'عرض الكل',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Text(
                        'الأقسام',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: categories.when(
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (items) => _CategoryGrid(items: items),
                ),
              ),
              // ── Products section ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/products'),
                        child: const Text(
                          'عرض الكل',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Text(
                        'الأطعمة المصنّعة',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              if (products.isLoading)
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100, child: Center(child: AppLoader())),
                )
              else if (products.error != null && products.items.isEmpty)
                SliverToBoxAdapter(
                  child: ErrorView(
                    message: products.error!,
                    onRetry: () => ref
                        .read(productsControllerProvider(const ProductQuery()).notifier)
                        .refresh(),
                  ),
                )
              else if (products.items.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyView(
                    icon: Icons.inventory_2_outlined,
                    title: 'لا توجد منتجات بعد',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.66,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final p = products.items[i];
                        return ProductCard(
                          product: p,
                          onTap: () => context.push('/product/${p.id}'),
                        );
                      },
                      childCount: products.items.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.cartCount, required this.unread});

  final int cartCount;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Back icon (visual left)
          _IconBox(
            child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.dark),
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          // Brand logo (center)
          const BrandLogo(size: 88, showLatin: false),
          const Spacer(),
          // Notification + cart (visual right)
          Row(
            children: [
              _NotifBox(unread: unread),
              const SizedBox(width: 8),
              _CartBox(count: cartCount),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _NotifBox extends StatelessWidget {
  const _NotifBox({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) {
    return _IconBox(
      onTap: () => context.push('/notifications'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined, size: 20, color: AppColors.dark),
          if (unread > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CartBox extends StatelessWidget {
  const _CartBox({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/cart'),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 20, color: Colors.white),
            if (count > 0)
              Positioned(
                top: -6,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
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

// ── Delivery row ──────────────────────────────────────────────────────────────

class _DeliveryRow extends StatelessWidget {
  const _DeliveryRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.primary),
          const SizedBox(width: 2),
          const Text(
            'الرياض - حي التخصص',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'توصيل إلى',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
        ],
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GestureDetector(
        onTap: () => context.push('/products'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: AppColors.muted, size: 20),
              SizedBox(width: 10),
              Text(
                'ابحث عن متجر...',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero banner ───────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: () => context.push('/products'),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF0C3A1C), Color(0xFF031608)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              // Basket image — left side
              Positioned(
                left: -8,
                bottom: 0,
                top: 0,
                width: 170,
                child: AppAssetImage(
                  AppAssets.heroBasket,
                  fit: BoxFit.contain,
                ),
              ),
              // Text content — right side
              Positioned(
                right: 16,
                top: 0,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                      ),
                      child: const Text(
                        'عروض خاصة',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'خصم\nحتى 40%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'تسوق الآن',
                        style: TextStyle(
                          color: Color(0xFF0C3A1C),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Carousel dots
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 16,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
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
}

// ── Category grid ─────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.items});

  final List<Category> items;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(10).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: visible.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 0.82,
          crossAxisSpacing: 6,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, i) {
          final c = visible[i];
          return GestureDetector(
            onTap: () => context.push(
              '/products',
              extra: ProductsArgs(categorySlug: c.slug, title: c.nameAr),
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: AppAssetImage(
                    AppAssets.categoryIcon(c.slug),
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  c.nameAr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
