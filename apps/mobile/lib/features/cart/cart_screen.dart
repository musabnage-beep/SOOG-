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
      backgroundColor: AppColors.background,
      body: SafeArea(child: _body(context, ref, state)),
      bottomNavigationBar: state.isEmpty ? null : _BottomBar(state: state),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, CartState state) {
    return Column(
      children: [
        _Header(count: state.cart?.items.length ?? 0),
        if (state.isLoading && state.cart == null)
          const Expanded(child: AppLoader())
        else if (state.isEmpty)
          Expanded(child: _emptyState(context))
        else
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () => ref.read(cartControllerProvider.notifier).load(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  for (final line in state.cart!.items) ...[
                    _CartTile(line: line),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 10),
                  const _NoteSection(),
                  const SizedBox(height: 22),
                  _PaymentSummary(subtotal: state.subtotal),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.shopping_cart_outlined,
          size: 72,
          color: AppColors.muted,
        ),
        const SizedBox(height: 16),
        const Text(
          'سلتك فارغة',
          style: TextStyle(
            color: AppColors.dark,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'تصفّح المنتجات وأضف ما يعجبك',
          style: TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () => context.go('/home'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'ابدأ التسوّق',
            style: TextStyle(color: AppColors.onPrimary, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'السلة',
                  style: TextStyle(
                    color: AppColors.dark,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count == 0 ? 'الضيافة' : 'الضيافة · $count أصناف',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('إضافة أصناف'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumb(url: line.image),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.nameAr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.35,
                    color: AppColors.dark,
                  ),
                ),
                if (line.unit != 'PIECE') ...[
                  const SizedBox(height: 4),
                  Text(
                    line.isCarton && line.unitsPerCarton != null
                        ? 'كرتون (${line.unitsPerCarton} حبة)'
                        : line.unitLabel ?? '',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  Formatters.money(line.lineTotal),
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Dropping to zero removes the line, so no separate delete button.
          QuantityStepper(
            quantity: line.quantity,
            min: 0,
            onChanged: (v) => notifier.setQuantity(line.id, v),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const fallback = Center(
      child: Icon(Icons.shopping_bag_outlined, color: AppColors.muted, size: 28),
    );
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: url == null || url!.isEmpty ? AppColors.surfaceAlt : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null || url!.isEmpty
          ? fallback
          : CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => fallback,
            ),
    );
  }
}

// ── Special requests ──────────────────────────────────────────────────────────
class _NoteSection extends ConsumerWidget {
  const _NoteSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(orderNoteProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('ملاحظات خاصة'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _edit(context, ref, note),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.muted,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: note.isEmpty
                    ? const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'هل لديك طلب خاص؟',
                            style: TextStyle(
                              color: AppColors.dark,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'أي شيء آخر نحتاج معرفته؟',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        note,
                        style: const TextStyle(
                          color: AppColors.dark,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
              ),
              const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, String note) async {
    final controller = TextEditingController(text: note);
    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('ملاحظات خاصة'),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'أي تعليمات خاصة بالطلب...',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'حفظ',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (saved != null) ref.read(orderNoteProvider.notifier).state = saved;
  }
}

// ── Payment summary ───────────────────────────────────────────────────────────
class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.subtotal});

  final double subtotal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('ملخّص الدفع'),
        const SizedBox(height: 14),
        _row('مجموع السلة', Formatters.money(subtotal)),
        const SizedBox(height: 10),
        // The fee depends on the delivery address, which is only chosen on the
        // next screen, so the cart cannot show a number yet.
        _row('رسوم التوصيل', 'تُحسب بعد اختيار العنوان', muted: true),
        const SizedBox(height: 14),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 14),
        _row('الإجمالي قبل التوصيل', Formatters.money(subtotal), bold: true),
      ],
    );
  }

  Widget _row(
    String label,
    String value, {
    bool bold = false,
    bool muted = false,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? AppColors.dark : AppColors.muted,
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: muted ? AppColors.muted : AppColors.dark,
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.dark,
      fontSize: 17,
      fontWeight: FontWeight.w800,
    ),
  );
}

// ── Bottom bar ────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state});

  final CartState state;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: state.mutating ? null : () => context.push('/checkout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              disabledBackgroundColor: AppColors.surfaceAlt,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'إتمام الطلب',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 10),
                Text(
                  Formatters.money(state.subtotal),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
