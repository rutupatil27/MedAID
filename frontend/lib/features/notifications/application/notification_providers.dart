import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/utils/live_polling.dart';
import '../../../shared/models/app_notification.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../data/notification_repository.dart';
import 'notification_links.dart';

/// How often the unread badge refreshes; null disables polling (tests).
final notificationPollIntervalProvider = Provider<Duration?>(
  (ref) => AppConfig.notificationPollInterval,
);

/// Unread count for the bell badge (P-09: push refreshes it at once, polling
/// covers devices without push).
class UnreadCountController extends AsyncNotifier<int> with LivePolling<int> {
  @override
  Duration get pollInterval =>
      ref.read(notificationPollIntervalProvider) ?? AppConfig.notificationPollInterval;

  @override
  bool shouldPoll(int value) => ref.read(notificationPollIntervalProvider) != null;

  @override
  Future<int> fetchLatest() => ref.read(notificationRepositoryProvider).unreadCount();

  @override
  Future<int> build() async {
    final count = await fetchLatest();
    startPolling(count);
    return count;
  }
}

final unreadCountProvider = AsyncNotifierProvider.autoDispose<UnreadCountController, int>(
  UnreadCountController.new,
);

/// The notification center list, newest first.
class NotificationsController extends AsyncNotifier<NotificationPage> {
  NotificationRepository get _repository => ref.read(notificationRepositoryProvider);

  @override
  Future<NotificationPage> build() => ref.watch(notificationRepositoryProvider).list();

  /// Marks [notification] read immediately in the list, then on the server.
  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead) return;
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        NotificationPage(
          items: [
            for (final item in current.items) item.id == notification.id ? item.markedRead() : item,
          ],
          unreadCount: math.max(0, current.unreadCount - 1),
          total: current.total,
        ),
      );
    }
    try {
      await _repository.markRead(notification.id);
    } finally {
      ref.invalidate(unreadCountProvider);
    }
  }

  Future<void> markAllRead() async {
    await _repository.markAllRead();
    ref.invalidate(unreadCountProvider);
    final latest = await _repository.list();
    if (ref.mounted) state = AsyncData(latest);
  }
}

final notificationsProvider =
    AsyncNotifierProvider.autoDispose<NotificationsController, NotificationPage>(
      NotificationsController.new,
    );

/// Opens what a notification is about, for both notification-center taps and
/// push taps. Marks it read and navigates only inside the signed-in role's
/// own area (see [notificationRoute]).
class NotificationOpener {
  NotificationOpener(this._ref);

  final Ref _ref;

  /// Returns false when there is no signed-in account to open it for.
  bool open({required String type, required Map<String, String> data, String? notificationId}) {
    final auth = _ref.read(authProvider).value;
    if (auth is! Authenticated || auth.user.mustChangePassword) return false;

    if (notificationId != null) {
      _ref.read(notificationRepositoryProvider).markRead(notificationId).ignore();
    }
    _ref.invalidate(unreadCountProvider);
    final route =
        notificationRoute(role: auth.user.role, type: type, data: data) ?? AppRoutes.notifications;
    unawaited(_ref.read(routerProvider).push(route));
    return true;
  }
}

final notificationOpenerProvider = Provider<NotificationOpener>(NotificationOpener.new);
