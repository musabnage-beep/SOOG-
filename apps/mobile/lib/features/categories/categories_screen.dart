import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/catalog_providers.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/app_asset.dart';
import '../../widgets/state_views.dart';
import '../products/products_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'الأقسام',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.dark,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: categories.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (items) => GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.78,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, i) {
            final c = items[i];
            return FadeSlideIn(
              index: i,
              offset: 14,
              child: PressableScale(
                onTap: () => context.push(
                  '/products',
                  extra: ProductsArgs(categorySlug: c.slug, title: c.nameAr),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.18),
                        ),
                        boxShadow: AppColors.cardShadow,
                      ),
                      alignment: Alignment.center,
                      child: CategoryArt(slug: c.slug, icon: c.icon, size: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.nameAr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
