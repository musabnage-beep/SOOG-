import '../../core/network/api_client.dart';
import '../models/product.dart';

class FavoritesRepository {
  FavoritesRepository(this._api);

  final ApiClient _api;

  Future<List<Product>> list() async {
    final data = await _api.get<List<dynamic>>('/favorites');
    return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> add(String productId) async {
    await _api.post<dynamic>('/favorites/$productId');
  }

  Future<void> remove(String productId) async {
    await _api.delete<dynamic>('/favorites/$productId');
  }
}
