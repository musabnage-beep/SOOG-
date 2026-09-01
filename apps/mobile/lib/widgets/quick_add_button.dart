import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/snack.dart';
import '../data/models/product.dart';
import '../providers/auth_controller.dart';
import '../providers/cart_controller.dart';

/// Round add-to-cart button that sits on a product photo.
///
/// Once the product is in the cart the button turns into its quantity, so a
/// card shows at a glance what is already ordered; tapping again adds one more.
/// Guests see nothing — they cannot have a cart.
class QuickAddButton extends ConsumerStatefulWidget {
  const QuickAddButton({super.key, required this.product, this.size = 32});

  final Product product;
  final double size;

  @override
  ConsumerState<QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends ConsumerState<QuickAddButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(authControllerProvider).isAuthenticated) {
      return const SizedBox.shrink();
    }

    final inCart = ref
        .watch(cartControllerProvider)
        .cart
        ?.items
        .where((l) => l.productId == widget.product.id)
        .fold<int>(0, (sum, l) => sum + l.quantity);
    final quantity = inCart ?? 0;
    final disabled = widget.product.isOutOfStock || _busy;
    final filled = quantity > 0;

    return Material(
      color: filled ? AppColors.primary : AppColors.surface,
      shape: CircleBorder(
        side: BorderSide(
          color: filled ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: disabled ? null : _add,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: _busy
                ? SizedBox(
                    width: widget.size * 0.45,
                    height: widget.size * 0.45,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.muted,
                    ),
                  )
                : filled
                ? Text(
                    '$quantity',
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: widget.size * 0.44,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Icon(
                    Icons.add_rounded,
                    size: widget.size * 0.58,
                    color: disabled ? AppColors.muted : AppColors.primary,
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _add() async {
    setState(() => _busy = true);
    try {
      await ref.read(cartControllerProvider.notifier).add(widget.product.id);
    } catch (e) {
      if (mounted) showErrorSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
