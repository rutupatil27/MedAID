import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_config.dart';
import 'push_service.dart';

/// Firebase Cloud Messaging (doc 19). Firebase is configured from
/// `--dart-define` values, so no generated config files are needed.
bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

/// Firebase configuration from `--dart-define`. Shared with the background
/// isolate, which has to initialise Firebase for itself.
FirebaseOptions firebaseOptions() => FirebaseOptions(
  apiKey: AppConfig.firebaseApiKey,
  appId: _isIos ? AppConfig.firebaseIosAppId : AppConfig.firebaseAndroidAppId,
  messagingSenderId: AppConfig.firebaseMessagingSenderId,
  projectId: AppConfig.firebaseProjectId,
);

class FirebasePushService implements PushService {
  Future<FirebaseMessaging>? _messaging;

  Future<FirebaseMessaging> _ready() => _messaging ??= () async {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: firebaseOptions());
    return FirebaseMessaging.instance;
  }();

  static PushMessage _toMessage(RemoteMessage message) => PushMessage(
    data: {for (final e in message.data.entries) e.key: '${e.value}'},
    title: message.notification?.title,
    body: message.notification?.body,
  );

  /// Firebase streams need Firebase initialised first.
  Stream<T> _after<T>(Stream<T> Function() source) async* {
    await _ready();
    yield* source();
  }

  @override
  bool get isEnabled => true;

  @override
  String get platform => _isIos ? 'ios' : 'android';

  @override
  Future<bool> requestPermission() async {
    final settings = await (await _ready()).requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() async => (await _ready()).getToken();

  @override
  Future<void> deleteToken() async => (await _ready()).deleteToken();

  @override
  Stream<String> get onTokenRefresh => _after(() => FirebaseMessaging.instance.onTokenRefresh);

  @override
  Stream<PushMessage> get onForegroundMessage =>
      _after(() => FirebaseMessaging.onMessage.map(_toMessage));

  @override
  Stream<PushMessage> get onMessageOpened =>
      _after(() => FirebaseMessaging.onMessageOpenedApp.map(_toMessage));

  @override
  Future<PushMessage?> initialMessage() async {
    final message = await (await _ready()).getInitialMessage();
    return message == null ? null : _toMessage(message);
  }
}
