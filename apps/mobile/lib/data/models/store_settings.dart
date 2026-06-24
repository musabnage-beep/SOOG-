import '../../core/utils/json.dart';

class StoreSettings {
  StoreSettings({
    required this.storeLatitude,
    required this.storeLongitude,
    required this.freeDeliveryRadiusM,
    required this.deliveryRadiusM,
    required this.baseDeliveryFee,
    this.currency = 'SAR',
    this.storeName,
    this.storePhone,
  });

  final double storeLatitude;
  final double storeLongitude;
  final int freeDeliveryRadiusM;
  final int deliveryRadiusM;
  final double baseDeliveryFee;
  final String currency;
  final String? storeName;
  final String? storePhone;

  factory StoreSettings.fromJson(Map<String, dynamic> json) => StoreSettings(
        storeLatitude: asDouble(json['storeLatitude'] ?? json['storeLat'], 24.7136),
        storeLongitude: asDouble(json['storeLongitude'] ?? json['storeLng'], 46.6753),
        freeDeliveryRadiusM: asInt(json['freeDeliveryRadiusM'], 3000),
        deliveryRadiusM: asInt(json['deliveryRadiusM'], 15000),
        baseDeliveryFee: asDouble(json['baseDeliveryFee'], 15),
        currency: asString(json['currency'], 'SAR'),
        storeName: json['storeName'] as String?,
        storePhone: json['storePhone'] as String?,
      );
}
