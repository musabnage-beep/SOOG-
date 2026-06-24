import 'package:dio/dio.dart';

/// A normalized error surfaced to the UI with an Arabic-friendly message.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.error});

  final String message;
  final int? statusCode;
  final String? error;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;

  /// Builds an [ApiException] from any thrown [DioException].
  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    if (response != null && response.data is Map) {
      final data = response.data as Map;
      final raw = data['message'];
      String message;
      if (raw is List && raw.isNotEmpty) {
        message = raw.first.toString();
      } else if (raw is String && raw.isNotEmpty) {
        message = raw;
      } else {
        message = _statusMessage(response.statusCode);
      }
      return ApiException(
        message,
        statusCode: response.statusCode,
        error: data['error']?.toString(),
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return ApiException('انتهت مهلة الاتصال. حاول مرة أخرى.');
      case DioExceptionType.connectionError:
        return ApiException('تعذّر الاتصال بالخادم. تحقّق من الإنترنت.');
      default:
        return ApiException(_statusMessage(e.response?.statusCode));
    }
  }

  static String _statusMessage(int? code) {
    switch (code) {
      case 400:
        return 'طلب غير صالح.';
      case 401:
        return 'انتهت الجلسة. الرجاء تسجيل الدخول مجدداً.';
      case 403:
        return 'ليست لديك صلاحية لهذا الإجراء.';
      case 404:
        return 'العنصر غير موجود.';
      case 409:
        return 'هذا العنصر موجود مسبقاً.';
      case 429:
        return 'محاولات كثيرة. حاول لاحقاً.';
      default:
        return 'حدث خطأ غير متوقع.';
    }
  }
}
