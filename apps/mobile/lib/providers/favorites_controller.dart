import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/product.dart';
import 'auth_controller.dart';
import 'core_providers.dart';

class FavoritesState {
  const FavoritesState({
    this.items = const [],
    this.ids = const {},
    this.isLoading = false,
    this.error,
  });

  final List<Product> items;
  final Set<String> ids;
  final bool isLoading;
  final String? error;

  bool contains(String productId) => ids.contains(productId);

  FavoritesState copyWith({
    List<Product>? items,
    Set<String>? ids,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      FavoritesState(
        items: items ?? this.items,
        ids: ids ?? this.ids,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class FavoritesController extends StateNotifier<FavoritesState> {
  FavoritesController(this._ref) : super(const FavoritesState());

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _ref.read(favoritesRepositoryProvider).list();
      state = FavoritesState(items: items, ids: items.map((p) => p.id).toSet());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggle(Product product) async {
    final repo = _ref.read(favoritesRepositoryProvider);
    if (state.contains(product.id)) {
      final ids = {...state.ids}..remove(product.id);
      state = state.copyWith(
        ids: ids,
        items: state.items.where((p) => p.id != product.id).toList(),
      );
      try {
        await repo.remove(product.id);
      } catch (_) {
        await load();
      }
    } else {
      final ids = {...state.ids}..add(product.id);
      state = state.copyWith(ids: ids, items: [product, ...state.items]);
      try {
        await repo.add(product.id);
      } catch (_) {
        await load();
      }
    }
  }

  void reset() => state = const FavoritesState();
}

final favoritesControllerProvider =
    StateNotifierProvider<FavoritesController, FavoritesState>((ref) {
  final controller = FavoritesController(ref);
  ref.listen<AuthState>(authControllerProvider, (prev, next) {
    if (next.isAuthenticated && prev?.isAuthenticated != true) {
      controller.load();
    } else if (!next.isAuthenticated) {
      controller.reset();
    }
  });
  if (ref.read(authControllerProvider).isAuthenticated) controller.load();
  return controller;
});
