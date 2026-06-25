import '../../core/network/api_client.dart';
import '../models/category.dart';
import '../models/paginated.dart';
import '../models/product.dart';

class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;

  Future<List<Category>> categories() async {
    final data = await _api.get<List<dynamic>>('/categories');
    return data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Paginated<Product>> products({
    String? categoryId,
    String? categorySlug,
    String? search,
    String? sort,
    bool inStockOnly = false,
    int page = 1,
    int limit = 20,
  }) async {
    final data = await _api.get<Map<String, dynamic>>('/products', query: {
      'page': page,
      'limit': limit,
      'categoryId': ?categoryId,
      'categorySlug': ?categorySlug,
      if (search != null && search.isNotEmpty) 'search': search,
      'sort': ?sort,
      if (inStockOnly) 'inStock': 'true',
    });
    return Paginated.fromJson(data, (m) => Product.fromJson(m));
  }

  Future<Product> product(String id) async {
    final data = await _api.get<Map<String, dynamic>>('/products/$id');
    return Product.fromJson(data);
  }
}
