import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/utils/json.dart';
import '../../../shared/models/app_notification.dart';

/// Notification center (`/notifications`). Push registration lives in
/// `core/notifications/device_registration.dart`.
class NotificationRepository {
  const NotificationRepository(this._api);

  final ApiClient _api;

  Future<NotificationPage> list({int limit = 50}) =>
      _api.get('/notifications', query: {'limit': limit}, decode: NotificationPage.fromJson);

  Future<int> unreadCount() => _api.get(
    '/notifications/unread-count',
    decode: (data) => asInt(asJsonMap(data)['unreadCount']) ?? 0,
  );

  Future<void> markRead(String id) => _api.patch<void>('/notifications/$id/read');

  Future<void> markAllRead() => _api.post<void>('/notifications/read-all');
}

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(apiClientProvider)),
);
