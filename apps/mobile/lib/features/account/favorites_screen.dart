import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/favorites_controller.dart';
import '../../widgets/product_card.dart';
import '../../widgets/state_views.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(favoritesControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoritesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المفضّلة')),
      body: state.isLoading
          ? const AppLoader()
          : state.items.isEmpty
              ? EmptyView(
                  icon: Icons.favorite_border,
                  title: 'لا توجد مفضّلات',
                  subtitle: 'أضف المنتجات التي تعجبك للوصول السريع',
                  action: ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('تصفّح المنتجات'),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(favoritesControllerProvider.notifier).load(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.66,
                    ),
                    itemCount: state.items.length,
                    itemBuilder: (_, i) {
                      final p = state.items[i];
                      return ProductCard(
                        product: p,
                        onTap: () => context.push('/product/${p.id}'),
                      );
                    },
                  ),
                ),
    );
  }
}
