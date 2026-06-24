import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/push/push_service.dart';
import '../core/storage/token_storage.dart';
import '../data/repositories/address_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/cart_repository.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/delivery_repository.dart';
import '../data/repositories/favorites_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/order_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  // The session-expired callback is wired in [authControllerProvider] after the
  // controller exists, to avoid a provider initialization cycle.
  return ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
});

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.watch(apiClientProvider)));

final catalogRepositoryProvider =
    Provider<CatalogRepository>((ref) => CatalogRepository(ref.watch(apiClientProvider)));

final cartRepositoryProvider =
    Provider<CartRepository>((ref) => CartRepository(ref.watch(apiClientProvider)));

final favoritesRepositoryProvider =
    Provider<FavoritesRepository>((ref) => FavoritesRepository(ref.watch(apiClientProvider)));

final addressRepositoryProvider =
    Provider<AddressRepository>((ref) => AddressRepository(ref.watch(apiClientProvider)));

final deliveryRepositoryProvider =
    Provider<DeliveryRepository>((ref) => DeliveryRepository(ref.watch(apiClientProvider)));

final orderRepositoryProvider =
    Provider<OrderRepository>((ref) => OrderRepository(ref.watch(apiClientProvider)));

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) => NotificationRepository(ref.watch(apiClientProvider)));

final pushServiceProvider =
    Provider<PushService>((ref) => PushService(ref.watch(authRepositoryProvider)));
