import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/account_screen.dart';
import '../features/account/addresses_screen.dart';
import '../features/account/edit_profile_screen.dart';
import '../features/account/favorites_screen.dart';
import '../features/account/notifications_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/checkout/map_picker_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/main_shell.dart';
import '../features/orders/order_detail_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/products/product_detail_screen.dart';
import '../features/products/products_screen.dart';
import '../providers/auth_controller.dart';

/// Bridges Riverpod [AuthState] changes to go_router's [refreshListenable].
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;
      const authRoutes = {'/login', '/register', '/otp', '/forgot'};

      if (status == AuthStatus.unknown) {
        return loc == '/splash' ? null : '/splash';
      }
      if (status == AuthStatus.unauthenticated) {
        return authRoutes.contains(loc) ? null : '/login';
      }
      // authenticated
      if (loc == '/splash' || authRoutes.contains(loc)) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, state) {
          final args = state.extra as OtpArgs;
          return OtpScreen(args: args);
        },
      ),
      GoRoute(path: '/forgot', builder: (_, _) => const ForgotPasswordScreen()),

      // Main tabbed shell.
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (_, _, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
          GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
          GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
        ],
      ),

      // Detail routes (pushed over the shell, full screen).
      GoRoute(
        path: '/products',
        parentNavigatorKey: _rootKey,
        builder: (_, state) {
          final extra = state.extra as ProductsArgs?;
          return ProductsScreen(args: extra);
        },
      ),
      GoRoute(
        path: '/product/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/checkout',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/map-picker',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => MapPickerScreen(initial: state.extra as MapPickerArgs?),
      ),
      GoRoute(
        path: '/addresses',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const AddressesScreen(),
      ),
      GoRoute(
        path: '/favorites',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/order/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const EditProfileScreen(),
      ),
    ],
  );
});
