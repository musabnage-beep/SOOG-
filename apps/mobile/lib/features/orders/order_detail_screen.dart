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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد الإلغاء', style: TextStyle(color: AppColors.danger)),
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
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: async.when(
        loading: () => const AppLoader(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
        data: _content,
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (order) => _actions(order),
        orElse: () => null,
      ),
    );
  }

  Widget _content(Order order) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('طلب #${order.orderNumber}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            OrderStatusChip(status: order.status),
          ],
        ),
        if (order.createdAt != null) ...[
          const SizedBox(height: 4),
          Text(Formatters.date(order.createdAt!),
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
        if (order.status == OrderStatus.rejected && order.rejectionReason != null) ...[
          const SizedBox(height: 14),
          _banner(Icons.cancel, AppColors.danger, 'سبب الرفض: ${order.rejectionReason}'),
        ],
        if (order.needsConfirmation) ...[
          const SizedBox(height: 14),
          _banner(Icons.info_outline, AppColors.warning,
              'بعض المنتجات غير متوفرة بالكامل. راجع الطلب وأكّد المتابعة أو ألغِ الطلب.'),
        ],
        const SizedBox(height: 20),
        const _Title('المنتجات'),
        const SizedBox(height: 8),
        ...order.items.map(_itemRow),
        const SizedBox(height: 20),
        const _Title('ملخّص الدفع'),
        const SizedBox(height: 8),
        _summaryRow('الإجمالي الفرعي', Formatters.money(order.subtotal)),
        if (order.isDelivery)
          _summaryRow('رسوم التوصيل',
              order.deliveryFee == 0 ? 'مجاني' : Formatters.money(order.deliveryFee)),
        const Divider(height: 24),
        _summaryRow('الإجمالي', Formatters.money(order.total), bold: true),
        if (order.isDelivery && order.address != null) ...[
          const SizedBox(height: 20),
          const _Title('عنوان التوصيل'),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(order.address!.summary)),
            ],
          ),
        ],
        const SizedBox(height: 20),
        const _Title('تتبّع الحالة'),
        const SizedBox(height: 8),
        _Timeline(events: order.statusHistory),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _itemRow(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nameAr, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${item.quantity} × ${Formatters.money(item.unitPrice)}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                if (item.isUnavailable) ...[
                  const SizedBox(height: 4),
                  const Text('غير متوفر',
                      style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
          Text(Formatters.money(item.lineTotal),
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                  color: bold ? AppColors.dark : AppColors.muted,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  fontSize: bold ? 17 : 14,
                )),
            Text(value,
                style: TextStyle(
                  color: bold ? AppColors.primary : AppColors.dark,
                  fontWeight: FontWeight.w800,
                  fontSize: bold ? 17 : 14,
                )),
          ],
        ),
      );

  Widget _banner(IconData icon, Color color, String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: TextStyle(color: color))),
          ],
        ),
      );

  Widget? _actions(Order order) {
    final canCancel = order.status.isActive && !order.needsConfirmation;
    if (!order.needsConfirmation && !canCancel) return null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (order.needsConfirmation)
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : _confirmPartial,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('تأكيد المتابعة'),
                ),
              ),
            if (order.needsConfirmation) const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : _cancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
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

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800));
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.events});

  final List<OrderStatusEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Text('لا يوجد سجل بعد', style: TextStyle(color: AppColors.muted));
    }
    return Column(
      children: List.generate(events.length, (i) {
        final e = events[i];
        final isLast = i == events.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 2, color: AppColors.border),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.status.labelAr,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (e.createdAt != null)
                        Text(Formatters.date(e.createdAt!),
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 12)),
                      if (e.note != null && e.note!.isNotEmpty)
                        Text(e.note!,
                            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
