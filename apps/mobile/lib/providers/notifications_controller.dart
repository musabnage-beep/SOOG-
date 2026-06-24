import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_notification.dart';
import 'auth_controller.dart';
import 'core_providers.dart';

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  final List<AppNotification> items;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      NotificationsState(
        items: items ?? this.items,
        unreadCount: unreadCount ?? this.unreadCount,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class NotificationsController extends StateNotifier<NotificationsState> {
  NotificationsController(this._ref) : super(const NotificationsState());

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(notificationRepositoryProvider);
      final items = await repo.list();
      final count = await repo.unreadCount();
      state = NotificationsState(items: items, unreadCount: count);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      final count = await _ref.read(notificationRepositoryProvider).unreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (_) {
      // ignore
    }
  }

  Future<void> markRead(String id) async {
    final items = state.items
        .map((n) => n.id == id
            ? AppNotification(
                id: n.id,
                title: n.title,
                body: n.body,
                type: n.type,
                isRead: true,
                createdAt: n.createdAt,
                payload: n.payload,
              )
            : n)
        .toList();
    final unread = items.where((n) => !n.isRead).length;
    state = state.copyWith(items: items, unreadCount: unread);
    try {
      await _ref.read(notificationRepositoryProvider).markRead(id);
    } catch (_) {
      await load();
    }
  }

  Future<void> markAllRead() async {
    state = state.copyWith(
      items: state.items
          .map((n) => AppNotification(
                id: n.id,
                title: n.title,
                body: n.body,
                type: n.type,
                isRead: true,
                createdAt: n.createdAt,
                payload: n.payload,
              ))
          .toList(),
      unreadCount: 0,
    );
    try {
      await _ref.read(notificationRepositoryProvider).markAllRead();
    } catch (_) {
      await load();
    }
  }

  void reset() => state = const NotificationsState();
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>((ref) {
  final controller = NotificationsController(ref);
  ref.listen<AuthState>(authControllerProvider, (prev, next) {
    if (next.isAuthenticated && prev?.isAuthenticated != true) {
      controller.load();
    } else if (!next.isAuthenticated) {
      controller.reset();
    }
  });
  if (ref.read(authControllerProvider).isAuthenticated) controller.load();
  return controller;
});
