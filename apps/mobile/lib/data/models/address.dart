import '../../core/utils/json.dart';

class Address {
  Address({
    required this.id,
    this.label,
    this.country = 'SA',
    required this.city,
    required this.district,
    required this.street,
    this.postalCode,
    required this.latitude,
    required this.longitude,
    this.notes,
    this.isDefault = false,
  });

  final String id;
  final String? label;
  final String country;
  final String city;
  final String district;
  final String street;
  final String? postalCode;
  final double latitude;
  final double longitude;
  final String? notes;
  final bool isDefault;

  String get summary => '$street، $district، $city';

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: asString(json['id']),
        label: json['label'] as String?,
        country: asString(json['country'], 'SA'),
        city: asString(json['city']),
        district: asString(json['district']),
        street: asString(json['street']),
        postalCode: json['postalCode'] as String?,
        latitude: asDouble(json['latitude']),
        longitude: asDouble(json['longitude']),
        notes: json['notes'] as String?,
        isDefault: asBool(json['isDefault']),
      );
}
