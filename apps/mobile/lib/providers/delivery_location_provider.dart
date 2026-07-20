import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The customer's chosen delivery location, shown in the home top bar and used
/// to pre-fill checkout. Persisted locally so it survives app restarts.
class DeliveryLocation {
  const DeliveryLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final double latitude;
  final double longitude;
}

const _kLabelKey = 'delivery_label';
const _kLatKey = 'delivery_lat';
const _kLngKey = 'delivery_lng';

final deliveryLocationProvider =
    StateNotifierProvider<DeliveryLocationNotifier, DeliveryLocation?>(
  (ref) => DeliveryLocationNotifier(),
);

class DeliveryLocationNotifier extends StateNotifier<DeliveryLocation?> {
  DeliveryLocationNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final label = prefs.getString(_kLabelKey);
    final lat = prefs.getDouble(_kLatKey);
    final lng = prefs.getDouble(_kLngKey);
    if (label != null && lat != null && lng != null) {
      state = DeliveryLocation(label: label, latitude: lat, longitude: lng);
    }
  }

  Future<void> set(DeliveryLocation location) async {
    state = location;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLabelKey, location.label);
    await prefs.setDouble(_kLatKey, location.latitude);
    await prefs.setDouble(_kLngKey, location.longitude);
  }
}
