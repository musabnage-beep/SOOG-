import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/cart.dart';
import '../../providers/cart_controller.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/state_views.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cartControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سلة التسوّق'),
        automaticallyImplyLeading: false,
        actions: [
          if (!state.isEmpty)
            IconButton(
              onPressed: () => _confirmClear(context, ref),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _body(context, ref, state),
      bottomNavigationBar: state.isEmpty ? null : _summary(context, ref, state),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, CartState state) {
    if (state.isLoading && state.cart == null) return const AppLoader();
    if (state.isEmpty) {
      return EmptyView(
        icon: Icons.shopping_cart_outlined,
        title: 'سلتك فارغة',
        subtitle: 'تصفّح المنتجات وأضف ما يعجبك',
        action: ElevatedButton(
          onPressed: () => context.go('/home'),
          child: const Text('ابدأ التسوّق'),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(cartControllerProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.cart!.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _CartTile(line: state.cart!.items[i]),
      ),
    );
  }

  Widget _summary(BuildContext context, WidgetRef ref, CartState state) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الإجمالي الفرعي',
                    style: TextStyle(color: AppColors.muted)),
                Text(
                  Formatters.money(state.subtotal),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: state.mutating ? null : () => context.push('/checkout'),
              child: const Text('متابعة الدفع'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إفراغ السلة'),
        content: const Text('هل تريد حذف جميع المنتجات من السلة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(cartControllerProvider.notifier).clear();
            },
            child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _CartTile extends ConsumerWidget {
  const _CartTile({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartControllerProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 72,
              child: (line.image == null || line.image!.isEmpty)
                  ? Container(
                      color: AppColors.cream,
                      child: const Icon(Icons.shopping_bag_outlined,
                          color: AppColors.muted),
                    )
                  : CachedNetworkImage(
                      imageUrl: line.image!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(
                        color: AppColors.cream,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.nameAr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.money(line.unitPrice),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    QuantityStepper(
                      quantity: line.quantity,
                      min: 0,
                      onChanged: (v) => notifier.setQuantity(line.id, v),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => notifier.remove(line.id),
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
