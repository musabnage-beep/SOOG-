import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/order.dart';
import '../data/models/paginated.dart';
import 'core_providers.dart';

/// How often an open order is re-fetched so the customer sees the status the
/// employee dashboard just set. Polling stops once the order is terminal.
const _pollInterval = Duration(seconds: 15);

/// Schedules a single refetch after [_pollInterval]; re-armed on every load.
void _pollWhile(Ref ref, bool active) {
  if (!active) return;
  final timer = Timer(_pollInterval, ref.invalidateSelf);
  ref.onDispose(timer.cancel);
}

/// Paginated list of the signed-in customer's orders.
final myOrdersProvider = FutureProvider.autoDispose<Paginated<Order>>((ref) async {
  final page = await ref.watch(orderRepositoryProvider).myOrders();
  _pollWhile(ref, page.items.any((o) => o.status.isActive));
  return page;
});

/// Single order detail, refreshable via [ref.invalidate].
final orderDetailProvider = FutureProvider.autoDispose.family<Order, String>((ref, id) async {
  final order = await ref.watch(orderRepositoryProvider).myOrder(id);
  _pollWhile(ref, order.status.isActive);
  return order;
});
