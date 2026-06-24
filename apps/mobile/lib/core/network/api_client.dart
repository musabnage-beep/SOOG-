import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Thin wrapper around Dio that:
///  - attaches the bearer token,
///  - unwraps the backend `{ success, data }` envelope,
///  - transparently refreshes an expired access token once,
///  - maps failures to [ApiException].
class ApiClient {
  ApiClient({required TokenStorage tokenStorage, Dio? dio, this.onSessionExpired})
      : _tokens = tokenStorage,
        _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = Env.apiBaseUrl
      ..connectTimeout = Env.connectTimeout
      ..receiveTimeout = Env.receiveTimeout
      ..headers['Content-Type'] = 'application/json'
      ..validateStatus = (status) => status != null && status < 400;

    // Separate client for refresh calls to avoid interceptor recursion.
    _refreshDio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: Env.connectTimeout,
      receiveTimeout: Env.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokens.accessToken;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) async {
        final shouldRetry = error.response?.statusCode == 401 &&
            error.requestOptions.extra['retried'] != true;
        if (shouldRetry && await _refresh()) {
          try {
            final opts = error.requestOptions..extra['retried'] = true;
            final token = await _tokens.accessToken;
            opts.headers['Authorization'] = 'Bearer $token';
            final clone = await _dio.fetch<dynamic>(opts);
            return handler.resolve(clone);
          } catch (_) {
            // fall through to error
          }
        }
        if (error.response?.statusCode == 401) {
          await _tokens.clear();
          onSessionExpired?.call();
        }
        handler.next(error);
      },
    ));
  }

  final Dio _dio;
  late final Dio _refreshDio;
  final TokenStorage _tokens;

  /// Invoked when the session expires (refresh failed). Assigned after
  /// construction to avoid a provider initialization cycle.
  void Function()? onSessionExpired;

  bool _refreshing = false;

  Future<bool> _refresh() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final refresh = await _tokens.refreshToken;
      if (refresh == null) return false;
      final res = await _refreshDio.post<dynamic>('/auth/refresh', data: {'refreshToken': refresh});
      final data = (res.data as Map)['data'] as Map;
      await _tokens.save(
        access: data['accessToken'] as String,
        refresh: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
  }

  /// Unwraps `{ success, data }` and returns `data` as [T].
  T _unwrap<T>(Response<dynamic> res) {
    final body = res.data;
    if (body is Map && body.containsKey('data')) return body['data'] as T;
    return body as T;
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) async {
    return _run(() => _dio.get<dynamic>(path, queryParameters: query));
  }

  Future<T> post<T>(String path, {Object? data}) async {
    return _run(() => _dio.post<dynamic>(path, data: data));
  }

  Future<T> patch<T>(String path, {Object? data}) async {
    return _run(() => _dio.patch<dynamic>(path, data: data));
  }

  Future<T> put<T>(String path, {Object? data}) async {
    return _run(() => _dio.put<dynamic>(path, data: data));
  }

  Future<T> delete<T>(String path, {Object? data}) async {
    return _run(() => _dio.delete<dynamic>(path, data: data));
  }

  Future<T> _run<T>(Future<Response<dynamic>> Function() request) async {
    try {
      final res = await request();
      return _unwrap<T>(res);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
