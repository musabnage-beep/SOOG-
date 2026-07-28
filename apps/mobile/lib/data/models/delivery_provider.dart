import '../../core/utils/json.dart';

/// External shipping company offered outside the free-delivery area.
class DeliveryProvider {
  DeliveryProvider({
    required this.id,
    required this.name,
    required this.deliveryFee,
    required this.estimatedDays,
    this.logo,
    this.phone,
    this.website,
    this.isActive = true,
  });

  final String id;
  final String name;
  final double deliveryFee;
  final int estimatedDays;
  final String? logo;
  final String? phone;
  final String? website;
  final bool isActive;

  factory DeliveryProvider.fromJson(Map<String, dynamic> json) => DeliveryProvider(
        id: asString(json['id']),
        name: asString(json['name']),
        deliveryFee: asDouble(json['deliveryFee']),
        estimatedDays: asInt(json['estimatedDays'], 2),
        logo: json['logo'] as String?,
        phone: json['phone'] as String?,
        website: json['website'] as String?,
        isActive: asBool(json['isActive']),
      );
}
