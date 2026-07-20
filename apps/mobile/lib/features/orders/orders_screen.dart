import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order.dart';
import '../../providers/orders_providers.dart';
import '../../widgets/order_status_chip.dart';
import '../../widgets/state_views.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلباتي'),
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: orders.when(
        loading: () => const AppLoader(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(myOrdersProvider),
        ),
        data: (page) {
          if (page.items.isEmpty) {
            return EmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'لا توجد طلبات',
              subtitle: 'ابدأ بالتسوّق وستظهر طلباتك هنا',
              action: ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('ابدأ التسوّق'),
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(myOrdersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: page.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _OrderCard(order: page.items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/order/${order.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('طلب #${order.orderNumber}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                OrderStatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            if (order.createdAt != null)
              Text(Formatters.date(order.createdAt!),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  order.isDelivery ? Icons.delivery_dining : Icons.storefront,
                  size: 18,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 6),
                Text(order.isDelivery ? 'توصيل' : 'استلام',
                    style: const TextStyle(color: AppColors.muted)),
                const Spacer(),
                Text(Formatters.money(order.total),
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w800)),
              ],
            ),
            if (order.needsConfirmation) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                    SizedBox(width: 6),
                    Text('بانتظار تأكيدك على التعديلات',
                        style: TextStyle(color: AppColors.warning, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
