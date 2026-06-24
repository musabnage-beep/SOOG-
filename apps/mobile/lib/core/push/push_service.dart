import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository.dart';

/// Wraps Firebase Cloud Messaging. All operations are best-effort: when Firebase
/// is not configured for the current platform (no `google-services.json` /
/// `GoogleService-Info.plist`), every method degrades to a no-op so the rest of
/// the app keeps working.
class PushService {
  PushService(this._authRepo);

  final AuthRepository _authRepo;

  bool _initialized = false;
  String? _token;

  /// Initializes Firebase + FCM once. Safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      _initialized = true;
    } catch (e) {
      // Firebase not configured — disable push silently.
      debugPrint('PushService: Firebase unavailable ($e)');
    }
  }

  /// Fetches the device token and registers it with the backend.
  Future<void> registerToken() async {
    if (!_initialized) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token == _token) return;
      _token = token;
      await _authRepo.registerFcmToken(token);
      FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
        _token = t;
        try {
          await _authRepo.registerFcmToken(t);
        } catch (_) {/* best-effort */}
      });
    } catch (e) {
      debugPrint('PushService: token registration failed ($e)');
    }
  }

  /// Unregisters the device token on logout.
  Future<void> unregister() async {
    final token = _token;
    if (token == null) return;
    try {
      await _authRepo.removeFcmToken(token);
    } catch (_) {/* best-effort */}
    _token = null;
  }
}
