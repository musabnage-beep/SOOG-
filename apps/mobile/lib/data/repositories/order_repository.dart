import '../../core/network/api_client.dart';
import '../models/order.dart';
import '../models/paginated.dart';

class OrderRepository {
  OrderRepository(this._api);

  final ApiClient _api;

  Future<Order> checkout({
    required FulfillmentType fulfillmentType,
    String? addressId,
    String? customerNote,
  }) async {
    final data = await _api.post<Map<String, dynamic>>('/orders/checkout', data: {
      'fulfillmentType': fulfillmentType == FulfillmentType.pickup ? 'PICKUP' : 'DELIVERY',
      'addressId': ?addressId,
      if (customerNote != null && customerNote.isNotEmpty) 'customerNote': customerNote,
    });
    return Order.fromJson(data);
  }

  Future<Paginated<Order>> myOrders({String? status, int page = 1, int limit = 20}) async {
    final data = await _api.get<Map<String, dynamic>>('/orders/mine', query: {
      'page': page,
      'limit': limit,
      'status': ?status,
    });
    return Paginated.fromJson(data, (m) => Order.fromJson(m));
  }

  Future<Order> myOrder(String id) async {
    final data = await _api.get<Map<String, dynamic>>('/orders/mine/$id');
    return Order.fromJson(data);
  }

  Future<Order> confirmPartial(String id) async {
    final data = await _api.post<Map<String, dynamic>>('/orders/mine/$id/confirm-partial');
    return Order.fromJson(data);
  }

  Future<Order> cancel(String id) async {
    final data = await _api.post<Map<String, dynamic>>('/orders/mine/$id/cancel');
    return Order.fromJson(data);
  }
}
