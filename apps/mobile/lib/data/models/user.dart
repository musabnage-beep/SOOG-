import '../../core/utils/json.dart';

class AppUser {
  AppUser({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.role = 'CUSTOMER',
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
  });

  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String role;
  final bool isEmailVerified;
  final bool isPhoneVerified;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final role = json['role'];
    return AppUser(
      id: asString(json['id']),
      fullName: asString(json['fullName']),
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: role is Map ? asString(role['name'], 'CUSTOMER') : asString(role, 'CUSTOMER'),
      isEmailVerified: asBool(json['isEmailVerified']),
      isPhoneVerified: asBool(json['isPhoneVerified']),
    );
  }
}
