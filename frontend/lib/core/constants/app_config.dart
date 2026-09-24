import 'package:flutter/foundation.dart';

/// Build-time configuration, injected with `--dart-define`.
///
/// Example:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5001/api/v1`
///
/// No secrets belong here: everything in the app binary is public.
abstract final class AppConfig {
  /// Where the backend runs while developing, so plain `flutter run` works.
  ///
  /// Change this to match your setup:
  ///   - physical phone: your computer's Wi-Fi address (`ipconfig` on Windows,
  ///     `ifconfig` elsewhere) and the backend `PORT`
  ///   - Android emulator: `http://10.0.2.2:5001/api/v1` (10.0.2.2 is the
  ///     emulator's alias for the host, and only works there)
  ///   - iOS simulator or desktop: `http://localhost:5001/api/v1`
  ///
  /// The phone and the computer must be on the same network.
  static const String devApiBaseUrl = 'http://192.168.18.170:5001/api/v1';

  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// `--dart-define=API_BASE_URL=...` wins. Debug builds fall back to
  /// [devApiBaseUrl]; a release build must be told its real server:
  /// `flutter build apk --dart-define=API_BASE_URL=https://api.example.org/api/v1`.
  static String get apiBaseUrl {
    if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
    // Not an assert: Dart strips those from release and profile builds, so a
    // shipped APK would quietly fall back to whatever LAN address a developer
    // last used and fail with an unexplained network error. Better to say so.
    if (!kDebugMode) {
      throw StateError(
        'No API_BASE_URL. Build with --dart-define-from-file=dart_defines.json, '
        'and give it the full base including /api/v1.',
      );
    }
    return devApiBaseUrl;
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 25);
  static const Duration sendTimeout = Duration(seconds: 60);

  /// Polling interval for live screens (P-09: push + polling, no WebSockets).
  static const Duration livePollInterval = Duration(seconds: 5);

  /// Must match the backend MAX_UPLOAD_MB (OQ-20); checked before uploading.
  static const int maxDocumentBytes = 5 * 1024 * 1024;

  /// How long SOS waits for a GPS fix before sending without it (OQ-15).
  static const Duration sosLocationTimeout = Duration(seconds: 8);

  /// Volunteer location tracking while ACTIVE/BUSY (OQ-32). A heartbeat keeps a
  /// stationary volunteer fresh: it must stay well below the backend
  /// LOCATION_STALE_SECONDS (300 s) or the volunteer stops being dispatched.
  static const int trackingDistanceFilterMeters = 25;
  static const Duration trackingInterval = Duration(seconds: 30);
  static const Duration trackingHeartbeat = Duration(seconds: 60);
  static const Duration trackingMinSendGap = Duration(seconds: 10);

  /// How often the response map refreshes the route/ETA (ORS quota friendly).
  static const Duration routeRefreshInterval = Duration(seconds: 60);

  /// OpenStreetMap tile template. Replaceable with a hosted tile provider.
  static const String mapTileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// Identifies the app to the tile server (OSM tile usage policy).
  static const String mapUserAgentPackageName = 'com.medaid.app';

  /// Push notifications (FCM). Off unless built with `--dart-define=ENABLE_PUSH=true`
  /// plus the Firebase app identifiers below (not secrets: they ship in every
  /// Firebase app). In-app notifications work either way.
  static const bool enablePush = bool.fromEnvironment('ENABLE_PUSH');
  static const String firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String firebaseAndroidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const String firebaseIosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');

  /// An unanswered emergency rings again this often, until it is accepted,
  /// declined or expires: one beep in a crowd is easy to miss.
  static const Duration alertRepeatInterval = Duration(seconds: 15);

  /// Unread badge refresh (push also refreshes it immediately).
  static const Duration notificationPollInterval = Duration(seconds: 30);
}
