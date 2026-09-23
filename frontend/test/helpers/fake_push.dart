import 'dart:async';

import 'package:medaid/core/notifications/push_service.dart';

/// Scriptable push delivery: tests add messages to the controllers.
class FakePushService implements PushService {
  FakePushService({this.token = 'device-token-123', this.initial});

  final String? token;
  PushMessage? initial;
  int permissionRequests = 0;

  final opened = StreamController<PushMessage>.broadcast();
  final foreground = StreamController<PushMessage>.broadcast();
  final refreshed = StreamController<String>.broadcast();

  @override
  bool get isEnabled => true;

  @override
  String get platform => 'android';

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<String> get onTokenRefresh => refreshed.stream;

  @override
  Stream<PushMessage> get onForegroundMessage => foreground.stream;

  @override
  Stream<PushMessage> get onMessageOpened => opened.stream;

  @override
  Future<PushMessage?> initialMessage() async {
    final message = initial;
    initial = null;
    return message;
  }
}
