import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_config.dart';
import 'firebase_push_service.dart';

/// A push message as the app sees it: event type plus IDs only (doc 19).
class PushMessage {
  const PushMessage({required this.data, this.title, this.body});

  final Map<String, String> data;
  final String? title;
  final String? body;

  String get type => data['type'] ?? '';

  String? get notificationId => data['notificationId'];
}

/// Push delivery behind an interface, so features and tests never depend on
/// Firebase directly and the app runs without Firebase configuration.
abstract interface class PushService {
  bool get isEnabled;

  /// `android` or `ios`, as the backend expects.
  String get platform;

  /// Asks for notification permission. Returns false when refused.
  Future<bool> requestPermission();

  Future<String?> getToken();

  Future<void> deleteToken();

  Stream<String> get onTokenRefresh;

  /// Received while the app is in the foreground (no system notification).
  Stream<PushMessage> get onForegroundMessage;

  /// The user tapped a notification while the app was in the background.
  Stream<PushMessage> get onMessageOpened;

  /// The notification tap that launched the app, if any.
  Future<PushMessage?> initialMessage();
}

/// Used when push is not configured: everything is a no-op.
class DisabledPushService implements PushService {
  const DisabledPushService();

  @override
  bool get isEnabled => false;

  @override
  String get platform => defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<PushMessage> get onForegroundMessage => const Stream.empty();

  @override
  Stream<PushMessage> get onMessageOpened => const Stream.empty();

  @override
  Future<PushMessage?> initialMessage() async => null;
}

final pushServiceProvider = Provider<PushService>(
  (ref) => AppConfig.enablePush ? FirebasePushService() : const DisabledPushService(),
);
