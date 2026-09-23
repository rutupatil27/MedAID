import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'background_alerts.dart';

/// A button on a notification, so the person can answer without opening the
/// app first.
class AlertAction {
  const AlertAction({required this.id, required this.label});

  final String id;
  final String label;
}

/// What the person did with a notification: tapped it, or pressed one of its
/// buttons ([actionId] is then that button's id).
class AlertResponse {
  const AlertResponse({required this.payload, this.actionId});

  final String payload;
  final String? actionId;
}

/// System notifications raised by the app itself, so a volunteer hears and
/// sees a new emergency even when they are not looking at the screen.
///
/// This is separate from push (`PushService`): push needs Firebase and only
/// shows something while the app is closed, while this works with no service
/// at all and is the only way to alert someone whose app is already open.
abstract interface class LocalNotifier {
  /// Prepares the channel. Safe to call more than once.
  Future<void> initialize();

  /// Android 13+ and iOS ask the person first. False means they refused.
  Future<bool> requestPermission();

  /// Shows a high-priority alert with sound and vibration.
  ///
  /// Showing the same [id] again rings again, which is how an unanswered
  /// emergency keeps calling for attention. [ongoing] keeps it from being
  /// swiped away while it still needs an answer.
  Future<void> showAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
    List<AlertAction> actions,
    bool ongoing,
  });

  Future<void> cancel(int id);

  /// Taps and button presses on alerts.
  Stream<AlertResponse> get onOpened;
}

/// Slightly longer than the two minutes an assignment can wait.
const _alertLifetime = Duration(minutes: 3);

/// `Notification.FLAG_INSISTENT`: Android repeats the channel's sound until the
/// notification goes away. This is what makes the alert *ring* rather than
/// chime once — and because Android does it, it keeps ringing when the app is
/// asleep or has been killed, where no Dart code of ours could play anything.
const _flagInsistent = 4;

/// The looping tone, as an Android raw resource rather than a Flutter asset:
/// the OS plays it without the app running. See
/// `android/app/src/main/res/raw/emergency_ring.wav`.
const _ringtone = RawResourceAndroidNotificationSound('emergency_ring');

/// The emergency channel: loud by design. Android shows these as heads-up
/// notifications, and the alarm audio usage means they are heard even when the
/// phone is on a low media volume.
///
/// Android freezes a channel's sound and importance when it is first created,
/// and later code changes are ignored. The id therefore carries a version:
/// changing how this channel sounds means a new id, and [_retiredChannels]
/// keeps the old ones from cluttering the phone's settings.
const _channel = AndroidNotificationChannel(
  'medaid_emergency_alerts_v3',
  'Emergency alerts',
  description: 'New emergencies assigned to you, and reminders to respond.',
  importance: Importance.max,
  playSound: true,
  sound: _ringtone,
  enableVibration: true,
  audioAttributesUsage: AudioAttributesUsage.alarm,
);

const _retiredChannels = ['medaid_emergency_alerts', 'medaid_emergency_alerts_v2'];

class FlutterLocalNotifier implements LocalNotifier {
  FlutterLocalNotifier([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _opened = StreamController<AlertResponse>.broadcast();
  bool _ready = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<void> initialize() async {
    if (_ready) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestSoundPermission: false,
            requestBadgePermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            _opened.add(AlertResponse(payload: payload, actionId: response.actionId));
          }
        },
        // Accept/Decline pressed while the app is not running: answered in a
        // background isolate, since there is no app to hand the response to.
        onDidReceiveBackgroundNotificationResponse: onBackgroundAlertResponse,
      );
      for (final retired in _retiredChannels) {
        await _android?.deleteNotificationChannel(channelId: retired);
      }
      await _android?.createNotificationChannel(_channel);
      _ready = true;
    } catch (error, stack) {
      // Never let notification setup break the app: the in-app list still works.
      debugPrint('Local notifications unavailable: $error\n$stack');
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      await initialize();
      final android = await _android?.requestNotificationsPermission();
      if (android != null) return android;
      final ios = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return ios ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
    List<AlertAction> actions = const [],
    bool ongoing = false,
  }) async {
    try {
      await initialize();
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        payload: payload,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.call,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            sound: _ringtone,
            // Ring again on every repeat until the emergency is answered.
            onlyAlertOnce: false,
            ongoing: ongoing,
            // Loop the tone while it waits for an answer. Paired with
            // [ongoing], which stops a swipe from silencing it.
            additionalFlags: ongoing ? Int32List.fromList([_flagInsistent]) : null,
            // Android clears it by itself if the app dies before the
            // assignment does, so a dead alert cannot sit there ringing.
            timeoutAfter: ongoing ? _alertLifetime.inMilliseconds : null,
            ticker: title,
            actions: [
              for (final action in actions)
                AndroidNotificationAction(
                  action.id,
                  action.label,
                  showsUserInterface: true,
                  cancelNotification: false,
                ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            // Breaks through Focus modes. "critical" would need Apple's
            // critical-alert entitlement, which this app does not have.
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
      );
    } catch (error) {
      debugPrint('Could not show notification: $error');
    }
  }

  @override
  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (_) {
      // Nothing to do: the notification is either gone or was never shown.
    }
  }

  @override
  Stream<AlertResponse> get onOpened => _opened.stream;
}

final localNotifierProvider = Provider<LocalNotifier>((ref) => FlutterLocalNotifier());
