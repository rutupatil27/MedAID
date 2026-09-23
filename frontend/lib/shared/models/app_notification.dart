import '../../core/utils/json.dart';

/// An in-app notification (`GET /notifications`). Title and body arrive
/// already localized to the account's language; `data` holds IDs only.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Object? value) {
    final json = asJsonMap(value);
    return AppNotification(
      id: asStringOr(json['id'], ''),
      type: asStringOr(json['type'], ''),
      title: asStringOr(json['title'], ''),
      body: asStringOr(json['body'], ''),
      data: {
        for (final entry in asJsonMap(json['data']).entries)
          if (entry.value != null) entry.key: '${entry.value}',
      },
      isRead: asBool(json['isRead']),
      createdAt: asDateTime(json['createdAt']),
    );
  }

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, String> data;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification markedRead() => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    data: data,
    isRead: true,
    createdAt: createdAt,
  );
}

/// One page of the notification center plus the account-wide unread count.
class NotificationPage {
  const NotificationPage({required this.items, required this.unreadCount, required this.total});

  factory NotificationPage.fromJson(Object? value) {
    final json = asJsonMap(value);
    return NotificationPage(
      items: [for (final item in asJsonList(json['items'])) AppNotification.fromJson(item)],
      unreadCount: asInt(json['unreadCount']) ?? 0,
      total: asInt(json['total']) ?? 0,
    );
  }

  final List<AppNotification> items;
  final int unreadCount;
  final int total;
}
