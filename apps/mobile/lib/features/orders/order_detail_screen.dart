import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order.dart';
import '../../providers/core_providers.dart';
import '../../providers/orders_providers.dart';
import '../../widgets/order_status_chip.dart';
import '../../widgets/state_views.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _busy = false;

  Future<void> _confirmPartial() async => _action(
    () => ref.read(orderRepositoryProvider).confirmPartial(widget.orderId),
    'تم تأكيد الطلب',
  );

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الطلب'),
        content: const Text('هل أنت متأكد من إلغاء هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'تأكيد الإلغاء',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _action(
        () => ref.read(orderRepositoryProvider).cancel(widget.orderId),
        'تم إلغاء الطلب',
      );
    }
  }

  Future<void> _action(Future<Order> Function() fn, String success) async {
    setState(() => _busy = true);
    try {
      await fn();
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(myOrdersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success), backgroundColor: AppColors.success),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orderDetailProvider(widget.orderId));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: async.when(
          loading: () => const AppLoader(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
          ),
          data: _body,
        ),
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (order) => _actions(order),
        orElse: () => null,
      ),
    );
  }

  Widget _body(Order order) {
    return Column(
      children: [
        const SizedBox(height: 16),
        // ── Pill title ───────────────────────────────────────────────
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(30),
              boxShadow: AppColors.glowGreen(intensity: 0.6),
            ),
            child: const Text(
              'تتبع الطلب',
              style: TextStyle(
                color: AppColors.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // ── Order meta row ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              OrderStatusChip(status: order.status),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '#${order.orderNumber}',
                    style: const TextStyle(
                      color: AppColors.dark,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  if (order.createdAt != null)
                    Text(
                      Formatters.shortDate(order.createdAt!),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // ── Horizontal step timeline ─────────────────────────────────
        _HorizontalTimeline(status: order.status),
        const SizedBox(height: 20),
        // ── Scrollable content ───────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async =>
                ref.invalidate(orderDetailProvider(widget.orderId)),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Map placeholder
                _MapPlaceholder(order: order),
                const SizedBox(height: 16),
                if (order.isDelivery &&
                    (order.status == OrderStatus.outForDelivery ||
                        order.status == OrderStatus.delivered)) ...[
                  const _DriverCard(),
                  const SizedBox(height: 16),
                ],
                // Banners
                if (order.status == OrderStatus.rejected &&
                    order.rejectionReason != null) ...[
                  _banner(
                    Icons.cancel,
                    AppColors.danger,
                    'سبب الرفض: ${order.rejectionReason}',
                  ),
                  const SizedBox(height: 12),
                ],
                if (order.needsConfirmation) ...[
                  _banner(
                    Icons.info_outline,
                    AppColors.warning,
                    'بعض المنتجات غير متوفرة. راجع الطلب وأكّد المتابعة أو ألغِ الطلب.',
                  ),
                  const SizedBox(height: 12),
                ],
                // Items
                const _SectionTitle('المنتجات'),
                const SizedBox(height: 8),
                ...order.items.map(_itemRow),
                const SizedBox(height: 16),
                // Payment summary
                const _SectionTitle('ملخّص الدفع'),
                const SizedBox(height: 8),
                _summaryCard(order),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _itemRow(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(
            Formatters.money(item.lineTotal),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.nameAr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} × ${Formatters.money(item.unitPrice)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                if (item.isUnavailable) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'غير متوفر',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          _summaryRow('الإجمالي الفرعي', Formatters.money(order.subtotal)),
          if (order.isDelivery)
            _summaryRow(
              'رسوم التوصيل',
              order.deliveryFee == 0
                  ? 'مجاني'
                  : Formatters.money(order.deliveryFee),
            ),
          const Divider(height: 20),
          _summaryRow('الإجمالي', Formatters.money(order.total), bold: true),
          const SizedBox(height: 4),
          _summaryRow('طريقة الدفع', order.paymentMethod.labelAr),
          _summaryRow('حالة الدفع', order.paymentStatus.labelAr),
          if (order.isDelivery && order.address != null) ...[
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.address!.summary,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: TextStyle(
                color: bold ? AppColors.primary : AppColors.dark,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                fontSize: bold ? 16 : 14,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: bold ? AppColors.dark : AppColors.muted,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                fontSize: bold ? 16 : 14,
              ),
            ),
          ],
        ),
      );

  Widget _banner(IconData icon, Color color, String text) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(color: color)),
        ),
      ],
    ),
  );

  Widget? _actions(Order order) {
    final canCancel = order.status.isActive && !order.needsConfirmation;
    if (!order.needsConfirmation && !canCancel) return null;
    return SafeArea(
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          children: [
            if (order.needsConfirmation)
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : _confirmPartial,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: const Size(0, 50),
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Text(
                          'تأكيد المتابعة',
                          style: TextStyle(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            if (order.needsConfirmation) const SizedBox(width: 12),
            if (canCancel)
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _cancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: const Size(0, 50),
                  ),
                  child: const Text('إلغاء الطلب'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Section title ──────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.right,
    style: const TextStyle(
      color: AppColors.dark,
      fontSize: 16,
      fontWeight: FontWeight.w800,
    ),
  );
}

// ── Horizontal 4-step timeline ─────────────────────────────────────────────────
class _HorizontalTimeline extends StatelessWidget {
  const _HorizontalTimeline({required this.status});
  final OrderStatus status;

  int get _activeStep {
    switch (status) {
      case OrderStatus.submitted:
      case OrderStatus.underReview:
      case OrderStatus.confirmationRequired:
      case OrderStatus.approved:
        return 0;
      case OrderStatus.preparing:
      case OrderStatus.ready:
        return 1;
      case OrderStatus.waitingForCourier:
      case OrderStatus.outForDelivery:
        return 2;
      case OrderStatus.delivered:
      case OrderStatus.pickedUp:
        return 3;
      case OrderStatus.rejected:
      case OrderStatus.cancelled:
        return -1; // no active step
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeStep;
    const steps = [
      (Icons.receipt_long_outlined, 'تم الطلب'),
      (Icons.inventory_2_outlined, 'جاري التجهيز'),
      (Icons.local_shipping_outlined, 'جاري التوصيل'),
      (Icons.check_circle_outline, 'تم التسليم'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line between steps
            final stepIndex = i ~/ 2;
            final filled = active >= 0 && stepIndex < active;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 22),
                child: Container(
                  height: 2,
                  color: filled ? AppColors.primary : AppColors.border,
                ),
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final done = active >= 0 && stepIndex <= active;
          final icon = steps[stepIndex].$1;
          final label = steps[stepIndex].$2;
          return Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: done ? null : AppColors.surfaceAlt,
                  gradient: done ? AppColors.primaryGradient : null,
                  shape: BoxShape.circle,
                  border: done
                      ? null
                      : Border.all(color: AppColors.border, width: 1.5),
                  boxShadow: done ? AppColors.glowGreen(intensity: 0.45) : null,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: done ? AppColors.onPrimary : AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 64,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: done ? AppColors.dark : AppColors.muted,
                    fontSize: 10,
                    fontWeight: done ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Map placeholder ────────────────────────────────────────────────────────────
class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: AppColors.heroGradient,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(double.infinity, 180),
            painter: _MapGridPainter(),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.glowGreen(intensity: 0.7),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.onPrimary,
                    size: 28,
                  ),
                ),
                Container(width: 3, height: 10, color: AppColors.primary),
              ],
            ),
          ),
          if (order.etaMinutes != null)
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'الوقت المتوقع: ${Formatters.eta(order.etaMinutes!)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter _) => false;
}

// ── Driver card ────────────────────────────────────────────────────────────────
class _DriverCard extends StatelessWidget {
  const _DriverCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          // Phone button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppColors.glowGreen(intensity: 0.5),
            ),
            child: const Icon(
              Icons.phone,
              color: AppColors.onPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Name + role
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مندوب التوصيل',
                  style: TextStyle(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'قيد التوصيل',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(Icons.person, color: AppColors.primary, size: 28),
          ),
        ],
      ),
    );
  }
}
