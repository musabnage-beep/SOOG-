import '../../core/utils/json.dart';

class DeliveryQuote {
  DeliveryQuote({
    required this.withinRange,
    required this.freeDelivery,
    required this.distanceMeters,
    required this.etaMinutes,
    required this.fee,
    this.currency = 'SAR',
  });

  final bool withinRange;
  final bool freeDelivery;
  final int distanceMeters;
  final int etaMinutes;
  final double fee;
  final String currency;

  factory DeliveryQuote.fromJson(Map<String, dynamic> json) => DeliveryQuote(
        withinRange: asBool(json['withinRange']),
        freeDelivery: asBool(json['freeDelivery']),
        distanceMeters: asInt(json['distanceMeters']),
        etaMinutes: asInt(json['etaMinutes']),
        fee: asDouble(json['fee']),
        currency: asString(json['currency'], 'SAR'),
      );
}
