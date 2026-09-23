/// Alerting a volunteer whose app is **not running**.
///
/// Everything here executes in a background isolate that Android spawns on
/// demand: there is no widget tree, no Riverpod container and no navigator, so
/// each entry point builds the little it needs and tears it down again.
///
/// The ring itself is not our problem here — the notification channel carries
/// the looping tone and Android plays it (see `local_notifier.dart`). This code
/// only has to *raise* the alert and answer its buttons.
library;

import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/localization/locale_provider.dart';
import '../constants/app_config.dart';
import '../network/auth_interceptor.dart';
import '../storage/preferences_storage.dart';
import '../storage/token_storage.dart';
import 'alert_actions.dart';
// Imports `local_notifier.dart`, which imports this file back for
// [onBackgroundAlertResponse]. The cycle is deliberate: both halves of the
// alert belong together, and the channel is defined in exactly one place.
import 'firebase_push_service.dart';
import 'local_notifier.dart';

/// The push type that means "an emergency has been dispatched to you".
const _assignmentPush = 'ASSIGNMENT_NEW';

/// Sent by `backend/scripts/send-test-push.js` to prove a Firebase setup
/// works. It is the only way to check the part that no test can reach: whether
/// Android really wakes this isolate for a killed app.
const _testPush = 'TEST';

/// Same formula as `AssignmentAlertsController`, so an alert raised from the
/// background and one raised in the app are the same notification rather than
/// two stacked copies of it.
int alertNotificationId(String assignmentId) => assignmentId.hashCode & 0x7fffffff;

/// Receives data-only pushes while the app is backgrounded or killed.
///
/// The backend deliberately sends **no** `notification` block: that would make
/// Android draw the alert itself, on its default channel, without the ring or
/// the buttons. Data-only wakes this isolate instead, so the alert is ours.
@pragma('vm:entry-point')
Future<void> onBackgroundPush(RemoteMessage message) async {
  final data = message.data;
  if (data['type'] == _testPush) {
    DartPluginRegistrant.ensureInitialized();
    // Not ongoing and carrying no buttons, so it sounds the tone once and can
    // be dismissed: a test must not behave like an emergency waiting for an
    // answer. Hearing that one tone also confirms the channel itself works.
    await FlutterLocalNotifier().showAlert(
      id: 0,
      title: '${data['title'] ?? 'MedAID test'}',
      body: '${data['body'] ?? 'Push is working.'}',
    );
    return;
  }
  if (data['type'] != _assignmentPush) return;
  final assignmentId = '${data['assignmentId'] ?? ''}';
  final emergencyId = '${data['emergencyId'] ?? ''}';
  if (assignmentId.isEmpty || emergencyId.isEmpty) return;

  DartPluginRegistrant.ensureInitialized();
  final l10n = await _localizations();
  await FlutterLocalNotifier().showAlert(
    id: alertNotificationId(assignmentId),
    // The backend localizes these to the volunteer's language; its own strings
    // are the right ones to show, and the fallbacks only matter if it stops
    // sending them.
    title: '${data['title'] ?? l10n.volunteerAlertNotificationTitle}',
    body: '${data['body'] ?? l10n.volunteerAlertNotificationBody}',
    payload: emergencyId,
    ongoing: true,
    actions: [
      AlertAction(id: acceptAction, label: l10n.volunteerAccept),
      AlertAction(id: declineAction, label: l10n.volunteerDecline),
    ],
  );
}

/// Accept or Decline pressed on an alert while the app is not running.
///
/// Answering here rather than launching the app keeps a decline to one tap,
/// which is the whole point of the buttons.
@pragma('vm:entry-point')
void onBackgroundAlertResponse(NotificationResponse response) {
  final emergencyId = response.payload;
  final action = response.actionId;
  if (emergencyId == null || emergencyId.isEmpty || action == null) return;
  unawaited(
    answerInBackground(emergencyId: emergencyId, action: action, notificationId: response.id),
  );
}

/// Calls the accept/decline endpoint with no app around it. Visible for tests.
Future<void> answerInBackground({
  required String emergencyId,
  required String action,
  int? notificationId,
}) async {
  final verb = switch (action) {
    acceptAction => 'accept',
    declineAction => 'decline',
    _ => null,
  };
  if (verb == null) return;

  DartPluginRegistrant.ensureInitialized();
  final dio = backgroundDio();
  try {
    await dio.post('/volunteers/me/emergencies/$emergencyId/$verb');
  } catch (error) {
    // Already taken, expired, or the session cannot be refreshed. The alert is
    // dismissed either way; opening the app shows what actually happened.
    debugPrint('Background $verb failed: $error');
  } finally {
    dio.close();
    // Stop the ring. Even when the call failed the volunteer has answered, and
    // the app re-raises the alert from live data if the server disagrees.
    if (notificationId != null) await FlutterLocalNotifier().cancel(notificationId);
  }
}

/// The same auth stack the app uses, built by hand because there is no
/// provider container in this isolate. Reusing [AuthInterceptor] means an
/// access token that expired while the app was closed is refreshed here too,
/// which is the common case for an alert arriving hours later.
@visibleForTesting
Dio backgroundDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.sendTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: const {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      storage: const SecureTokenStorage(),
      // Nowhere to send the volunteer: there is no app on screen to log out.
      onSessionExpired: () {},
    ),
  );
  return dio;
}

/// The volunteer's chosen language, for the button labels. Falls back to
/// English rather than failing the alert over a missing preference.
Future<AppLocalizations> _localizations() async {
  try {
    final prefs = PreferencesStorage(await SharedPreferences.getInstance());
    final locale = AppLocales.tryParse(prefs.localeCode) ?? AppLocales.english;
    return lookupAppLocalizations(locale);
  } catch (_) {
    return lookupAppLocalizations(AppLocales.english);
  }
}

/// Registers the background push handler. Called once at startup, before
/// `runApp`, because Android may deliver a message before the app is built.
Future<void> registerBackgroundPush() async {
  if (!AppConfig.enablePush) return;
  try {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: firebaseOptions());
    FirebaseMessaging.onBackgroundMessage(onBackgroundPush);
  } catch (error) {
    // Push is an extra: without it the app still alerts whenever it is running.
    debugPrint('Background push unavailable: $error');
  }
}
