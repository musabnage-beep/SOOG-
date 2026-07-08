import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/catalog_providers.dart';
import '../../widgets/product_card.dart';
import '../../widgets/state_views.dart';
class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsControllerProvider(const ProductQuery()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('العروض', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: products.isLoading
          ? const Center(child: AppLoader())
          : products.error != null && products.items.isEmpty
              ? ErrorView(
                  message: products.error!,
                  onRetry: () => ref
                      .read(productsControllerProvider(const ProductQuery()).notifier)
                      .refresh(),
                )
              : products.items.isEmpty
                  ? const EmptyView(
                      icon: Icons.local_offer_outlined,
                      title: 'لا توجد عروض حالياً',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: products.items.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.66,
                      ),
                      itemBuilder: (context, i) {
                        final p = products.items[i];
                        return ProductCard(
                          product: p,
                          onTap: () => context.push('/product/${p.id}'),
                        );
                      },
                    ),
    );
  }
}
