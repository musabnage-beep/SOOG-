import '../../core/network/api_client.dart';
import '../models/order.dart';
import '../models/paginated.dart';

class OrderRepository {
  OrderRepository(this._api);

  final ApiClient _api;

  Future<Order> checkout({
    required FulfillmentType fulfillmentType,
    PaymentMethod paymentMethod = PaymentMethod.cod,
    String? addressId,
    String? customerNote,
  }) async {
    final data = await _api.post<Map<String, dynamic>>('/orders/checkout', data: {
      'fulfillmentType': fulfillmentType == FulfillmentType.pickup ? 'PICKUP' : 'DELIVERY',
      'paymentMethod': paymentMethod.apiValue,
      'addressId': ?addressId,
      if (customerNote != null && customerNote.isNotEmpty) 'customerNote': customerNote,
    });
    return Order.fromJson(data);
  }

  /// Opens a gateway session for a card order and returns the hosted page URL.
  Future<String> initiatePayment(String orderId) async {
    final data = await _api.post<Map<String, dynamic>>('/payments/orders/$orderId/initiate');
    return data['redirectUrl'] as String;
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
