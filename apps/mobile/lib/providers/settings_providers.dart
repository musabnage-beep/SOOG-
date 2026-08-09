import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/delivery_quote.dart';
import '../data/models/store_settings.dart';
import 'core_providers.dart';

/// Public store settings (coordinates, delivery radius, fees).
final storeSettingsProvider = FutureProvider<StoreSettings>((ref) async {
  return ref.watch(deliveryRepositoryProvider).settings();
});

class DeliveryQuoteArgs {
  const DeliveryQuoteArgs({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is DeliveryQuoteArgs &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

final deliveryQuoteProvider =
    FutureProvider.family<DeliveryQuote, DeliveryQuoteArgs>((ref, args) async {
  return ref.watch(deliveryRepositoryProvider).quote(
        latitude: args.latitude,
        longitude: args.longitude,
      );
});
