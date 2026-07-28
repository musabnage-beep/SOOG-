import '../../core/network/api_client.dart';
import '../models/delivery_provider.dart';
import '../models/delivery_quote.dart';
import '../models/store_settings.dart';

class DeliveryRepository {
  DeliveryRepository(this._api);

  final ApiClient _api;

  Future<DeliveryQuote> quote({required double latitude, required double longitude}) async {
    final data = await _api.get<Map<String, dynamic>>('/delivery/quote',
        query: {'latitude': latitude, 'longitude': longitude});
    return DeliveryQuote.fromJson(data);
  }

  /// Active shipping companies the customer can pick outside the free area.
  Future<List<DeliveryProvider>> providers() async {
    final data = await _api.get<List<dynamic>>('/delivery/providers');
    return data.map((e) => DeliveryProvider.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<StoreSettings> settings() async {
    final data = await _api.get<Map<String, dynamic>>('/settings');
    return StoreSettings.fromJson(data);
  }
}
