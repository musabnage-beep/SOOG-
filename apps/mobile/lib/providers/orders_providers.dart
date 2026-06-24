import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/order.dart';
import '../data/models/paginated.dart';
import 'core_providers.dart';

/// Paginated list of the signed-in customer's orders.
final myOrdersProvider = FutureProvider<Paginated<Order>>((ref) async {
  return ref.watch(orderRepositoryProvider).myOrders();
});

/// Single order detail, refreshable via [ref.invalidate].
final orderDetailProvider = FutureProvider.family<Order, String>((ref, id) async {
  return ref.watch(orderRepositoryProvider).myOrder(id);
});
