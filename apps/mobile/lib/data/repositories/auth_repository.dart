import '../../core/network/api_client.dart';
import '../models/auth_result.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<String> register({
    required String fullName,
    String? email,
    String? phone,
    required String password,
  }) async {
    final data = await _api.post<Map<String, dynamic>>('/auth/register', data: {
      'fullName': fullName,
      'email': ?email,
      'phone': ?phone,
      'password': password,
    });
    return data['target'] as String;
  }

  Future<AuthResult> verifyOtp({
    required String target,
    required String code,
    required String purpose,
  }) async {
    final data = await _api.post<Map<String, dynamic>>('/auth/verify-otp', data: {
      'target': target,
      'code': code,
      'purpose': purpose,
    });
    return AuthResult.fromJson(data);
  }

  Future<void> resendOtp({required String target, required String purpose}) async {
    await _api.post<dynamic>('/auth/resend-otp', data: {'target': target, 'purpose': purpose});
  }

  Future<AuthResult> login({String? email, String? phone, required String password}) async {
    final data = await _api.post<Map<String, dynamic>>('/auth/login', data: {
      'email': ?email,
      'phone': ?phone,
      'password': password,
    });
    return AuthResult.fromJson(data);
  }

  Future<void> forgotPassword(String target) async {
    await _api.post<dynamic>('/auth/forgot-password', data: {'target': target});
  }

  Future<void> resetPassword({
    required String target,
    required String code,
    required String newPassword,
  }) async {
    await _api.post<dynamic>('/auth/reset-password', data: {
      'target': target,
      'code': code,
      'newPassword': newPassword,
    });
  }

  Future<void> logout(String? refreshToken) async {
    await _api.post<dynamic>('/auth/logout', data: {'refreshToken': refreshToken});
  }

  Future<AppUser> me() async {
    final data = await _api.get<Map<String, dynamic>>('/users/me');
    return AppUser.fromJson(data);
  }

  Future<void> registerFcmToken(String token) async {
    await _api.post<dynamic>('/auth/fcm-token', data: {'token': token});
  }

  Future<void> removeFcmToken(String token) async {
    await _api.delete<dynamic>('/auth/fcm-token', data: {'token': token});
  }

  Future<AppUser> updateProfile({String? fullName, String? email, String? phone}) async {
    final data = await _api.patch<Map<String, dynamic>>('/users/me', data: {
      'fullName': ?fullName,
      'email': ?email,
      'phone': ?phone,
    });
    return AppUser.fromJson(data);
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _api.patch<dynamic>('/users/me/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
