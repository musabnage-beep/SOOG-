import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/token_storage.dart';
import '../data/models/auth_result.dart';
import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';
import 'core_providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.user});

  final AuthStatus status;
  final AppUser? user;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({AuthStatus? status, AppUser? user}) =>
      AuthState(status: status ?? this.status, user: user ?? this.user);
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final controller = AuthController(
    repo: ref.watch(authRepositoryProvider),
    tokens: ref.watch(tokenStorageProvider),
  );
  // Wire the API client's session-expired callback now that the controller
  // exists (breaks the provider initialization cycle).
  ref.read(apiClientProvider).onSessionExpired = controller.onSessionExpired;
  controller.bootstrap();
  return controller;
});

class AuthController extends StateNotifier<AuthState> {
  AuthController({required AuthRepository repo, required TokenStorage tokens})
      : _repo = repo,
        _tokens = tokens,
        super(const AuthState());

  final AuthRepository _repo;
  final TokenStorage _tokens;

  /// Restores the session at startup.
  Future<void> bootstrap() async {
    if (!await _tokens.hasTokens()) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _repo.me();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await _tokens.clear();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _persist(AuthResult result) async {
    await _tokens.save(access: result.accessToken, refresh: result.refreshToken);
    state = AuthState(status: AuthStatus.authenticated, user: result.user);
  }

  Future<void> completeWithTokens(AuthResult result) => _persist(result);

  Future<void> login({String? email, String? phone, required String password}) async {
    final result = await _repo.login(email: email, phone: phone, password: password);
    await _persist(result);
  }

  void setUser(AppUser user) => state = state.copyWith(user: user);

  Future<void> logout() async {
    final refresh = await _tokens.refreshToken;
    try {
      await _repo.logout(refresh);
    } catch (_) {
      // best-effort
    }
    await _tokens.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Called by the API client when refresh fails.
  void onSessionExpired() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
