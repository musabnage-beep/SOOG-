import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/category.dart';
import '../data/models/paginated.dart';
import '../data/models/product.dart';
import 'core_providers.dart';

/// Public categories list (cached for the session).
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(catalogRepositoryProvider).categories();
});

/// Filter parameters that drive the product feed.
class ProductQuery {
  const ProductQuery({
    this.categoryId,
    this.categorySlug,
    this.search,
    this.sort = 'newest',
    this.inStockOnly = false,
  });

  final String? categoryId;
  final String? categorySlug;
  final String? search;
  final String sort;
  final bool inStockOnly;

  ProductQuery copyWith({
    String? categoryId,
    String? categorySlug,
    String? search,
    String? sort,
    bool? inStockOnly,
    bool clearCategory = false,
    bool clearSearch = false,
  }) =>
      ProductQuery(
        categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
        categorySlug: clearCategory ? null : (categorySlug ?? this.categorySlug),
        search: clearSearch ? null : (search ?? this.search),
        sort: sort ?? this.sort,
        inStockOnly: inStockOnly ?? this.inStockOnly,
      );

  @override
  bool operator ==(Object other) =>
      other is ProductQuery &&
      other.categoryId == categoryId &&
      other.categorySlug == categorySlug &&
      other.search == search &&
      other.sort == sort &&
      other.inStockOnly == inStockOnly;

  @override
  int get hashCode => Object.hash(categoryId, categorySlug, search, sort, inStockOnly);
}

class ProductsState {
  const ProductsState({
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<Product> items;
  final int page;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  bool get hasMore => page < totalPages;

  ProductsState copyWith({
    List<Product>? items,
    int? page,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) =>
      ProductsState(
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: clearError ? null : (error ?? this.error),
      );
}

class ProductsController extends StateNotifier<ProductsState> {
  ProductsController(this._ref, this.query) : super(const ProductsState()) {
    refresh();
  }

  final Ref _ref;
  final ProductQuery query;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _fetch(1);
      state = ProductsState(
        items: res.items,
        page: res.page,
        totalPages: res.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final res = await _fetch(state.page + 1);
      state = state.copyWith(
        items: [...state.items, ...res.items],
        page: res.page,
        totalPages: res.totalPages,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<Paginated<Product>> _fetch(int page) {
    return _ref.read(catalogRepositoryProvider).products(
          categoryId: query.categoryId,
          categorySlug: query.categorySlug,
          search: query.search,
          sort: query.sort,
          inStockOnly: query.inStockOnly,
          page: page,
        );
  }
}

final productsControllerProvider =
    StateNotifierProvider.family<ProductsController, ProductsState, ProductQuery>(
  (ref, query) => ProductsController(ref, query),
);

/// Single product detail.
final productProvider = FutureProvider.family<Product, String>((ref, id) async {
  return ref.watch(catalogRepositoryProvider).product(id);
});
