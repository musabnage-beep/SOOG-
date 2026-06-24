import '../../core/network/api_client.dart';
import '../models/cart.dart';

class CartRepository {
  CartRepository(this._api);

  final ApiClient _api;

  Future<Cart> getCart() async {
    final data = await _api.get<Map<String, dynamic>>('/cart');
    return Cart.fromJson(data);
  }

  Future<Cart> add(String productId, int quantity) async {
    final data = await _api.post<Map<String, dynamic>>('/cart/items',
        data: {'productId': productId, 'quantity': quantity});
    return Cart.fromJson(data);
  }

  Future<Cart> updateItem(String itemId, int quantity) async {
    final data = await _api.patch<Map<String, dynamic>>('/cart/items/$itemId',
        data: {'quantity': quantity});
    return Cart.fromJson(data);
  }

  Future<Cart> removeItem(String itemId) async {
    final data = await _api.delete<Map<String, dynamic>>('/cart/items/$itemId');
    return Cart.fromJson(data);
  }

  Future<Cart> clear() async {
    final data = await _api.delete<Map<String, dynamic>>('/cart');
    return Cart.fromJson(data);
  }
}
