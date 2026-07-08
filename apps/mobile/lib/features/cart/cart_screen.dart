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

const _kBg = Color(0xFF0A1A0C);

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cartControllerProvider);
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: _body(context, ref, state)),
      bottomNavigationBar: state.isEmpty ? null : _BottomBar(state: state),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, CartState state) {
    return Column(
      children: [
        const SizedBox(height: 16),
        // ── Title pill ──────────────────────────────────────────────
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'سلة التسوّق',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (state.isLoading && state.cart == null)
          const Expanded(child: AppLoader())
        else if (state.isEmpty)
          Expanded(child: _emptyState(context))
        else ...[
          // ── Count badge + label ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    state.cart!.items.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'سلة مشترياتك',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // ── Items list ──────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(cartControllerProvider.notifier).load(),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.cart!.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _CartTile(line: state.cart!.items[i]),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.white38),
        const SizedBox(height: 16),
        const Text(
          'سلتك فارغة',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'تصفّح المنتجات وأضف ما يعجبك',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () => context.go('/home'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text(
            'ابدأ التسوّق',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

// ── Cart tile ─────────────────────────────────────────────────────────────────
class _CartTile extends ConsumerWidget {
  const _CartTile({required this.line});
  final CartLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartControllerProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: (line.image == null || line.image!.isEmpty)
                ? const Center(
                    child: Icon(Icons.shopping_bag_outlined, color: AppColors.warning, size: 32),
                  )
                : CachedNetworkImage(
                    imageUrl: line.image!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.shopping_bag_outlined, color: AppColors.warning, size: 32),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  line.nameAr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 8),
                // Stepper + price + delete
                Row(
                  children: [
                    QuantityStepper(
                      quantity: line.quantity,
                      min: 0,
                      onChanged: (v) => notifier.setQuantity(line.id, v),
                    ),
                    const Spacer(),
                    Text(
                      Formatters.money(line.unitPrice),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => notifier.remove(line.id),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0x14DC2626),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                      ),
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

// ── Bottom bar ────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state});
  final CartState state;

  @override
  Widget build(BuildContext context) {
    final count = state.cart?.items.length ?? 0;
    final totalQty = state.cart?.items.fold<int>(0, (s, i) => s + i.quantity) ?? 0;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        color: _kBg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.rawNumber(state.subtotal),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  'الإجمالي ($count منتجات $totalQty)',
                  style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: state.mutating ? null : () => context.push('/checkout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'إتمام الطلب',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
