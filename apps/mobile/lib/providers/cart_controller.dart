import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/cart.dart';
import 'auth_controller.dart';
import 'core_providers.dart';

class CartState {
  const CartState({
    this.cart,
    this.isLoading = false,
    this.mutating = false,
    this.error,
  });

  final Cart? cart;
  final bool isLoading;
  final bool mutating;
  final String? error;

  int get count => cart?.totalQuantity ?? 0;
  double get subtotal => cart?.subtotal ?? 0;
  bool get isEmpty => cart?.isEmpty ?? true;

  CartState copyWith({
    Cart? cart,
    bool? isLoading,
    bool? mutating,
    String? error,
    bool clearError = false,
  }) =>
      CartState(
        cart: cart ?? this.cart,
        isLoading: isLoading ?? this.isLoading,
        mutating: mutating ?? this.mutating,
        error: clearError ? null : (error ?? this.error),
      );
}

class CartController extends StateNotifier<CartState> {
  CartController(this._ref) : super(const CartState());

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cart = await _ref.read(cartRepositoryProvider).getCart();
      state = CartState(cart: cart);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> add(String productId, {int quantity = 1}) async {
    await _mutate(() => _ref.read(cartRepositoryProvider).add(productId, quantity));
  }

  Future<void> setQuantity(String itemId, int quantity) async {
    if (quantity <= 0) {
      await remove(itemId);
      return;
    }
    await _mutate(() => _ref.read(cartRepositoryProvider).updateItem(itemId, quantity));
  }

  Future<void> remove(String itemId) async {
    await _mutate(() => _ref.read(cartRepositoryProvider).removeItem(itemId));
  }

  Future<void> clear() async {
    await _mutate(() => _ref.read(cartRepositoryProvider).clear());
  }

  void reset() => state = const CartState();

  Future<void> _mutate(Future<Cart> Function() action) async {
    state = state.copyWith(mutating: true, clearError: true);
    try {
      final cart = await action();
      state = CartState(cart: cart);
    } catch (e) {
      state = state.copyWith(mutating: false, error: e.toString());
      rethrow;
    }
  }
}

final cartControllerProvider = StateNotifierProvider<CartController, CartState>((ref) {
  final controller = CartController(ref);
  // Load the cart whenever the user becomes authenticated; reset on logout.
  ref.listen<AuthState>(authControllerProvider, (prev, next) {
    if (next.isAuthenticated && prev?.isAuthenticated != true) {
      controller.load();
    } else if (!next.isAuthenticated) {
      controller.reset();
    }
  });
  final auth = ref.read(authControllerProvider);
  if (auth.isAuthenticated) controller.load();
  return controller;
});
