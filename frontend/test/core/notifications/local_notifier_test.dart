import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medaid/core/notifications/alert_actions.dart';
import 'package:medaid/core/notifications/local_notifier.dart';
import 'package:mocktail/mocktail.dart';

class MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class FakeInitializationSettings extends Fake implements InitializationSettings {}

class FakeNotificationDetails extends Fake implements NotificationDetails {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeInitializationSettings());
    registerFallbackValue(FakeNotificationDetails());
  });

  late MockPlugin plugin;
  late FlutterLocalNotifier notifier;

  setUp(() {
    plugin = MockPlugin();
    notifier = FlutterLocalNotifier(plugin);
    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
        onDidReceiveBackgroundNotificationResponse: any(
          named: 'onDidReceiveBackgroundNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async => true);
    // No Android implementation in a unit test: channel setup is skipped.
    when(
      () => plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>(),
    ).thenReturn(null);
    when(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
        notificationDetails: any(named: 'notificationDetails'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<AndroidNotificationDetails> showAndCapture({bool ongoing = true}) async {
    await notifier.showAlert(
      id: 1,
      title: 'New emergency near you',
      body: 'Respond within 2 minutes.',
      payload: 'e1',
      ongoing: ongoing,
      actions: const [
        AlertAction(id: acceptAction, label: 'Accept'),
        AlertAction(id: declineAction, label: 'Decline'),
      ],
    );
    final details =
        verify(
              () => plugin.show(
                id: any(named: 'id'),
                title: any(named: 'title'),
                body: any(named: 'body'),
                payload: any(named: 'payload'),
                notificationDetails: captureAny(named: 'notificationDetails'),
              ),
            ).captured.single
            as NotificationDetails;
    return details.android!;
  }

  test('an alert waiting for an answer rings on a loop, played by Android', () async {
    final android = await showAndCapture();

    // FLAG_INSISTENT: the OS repeats the channel's sound until the
    // notification goes away, which is what keeps it ringing when the app has
    // been killed and no Dart code of ours could play anything.
    expect(android.additionalFlags, isNotNull);
    expect(android.additionalFlags!.contains(4), isTrue, reason: 'FLAG_INSISTENT');
    // Loud enough to be heard on a low media volume, and our own tone.
    expect(android.audioAttributesUsage, AudioAttributesUsage.alarm);
    expect(android.sound, isA<RawResourceAndroidNotificationSound>());
    expect(android.ongoing, isTrue);
  });

  test('an alert that needs no answer does not ring on a loop', () async {
    final android = await showAndCapture(ongoing: false);

    expect(android.additionalFlags, isNull);
  });

  test('the alert carries Accept and Decline', () async {
    final android = await showAndCapture();

    expect(android.actions!.map((a) => a.id), [acceptAction, declineAction]);
    // Pressing one must not clear the notification before the answer is sent.
    expect(android.actions!.every((a) => a.cancelNotification == false), isTrue);
  });

  test('a killed app can still answer, so a background handler is registered', () async {
    await notifier.initialize();

    final handler = verify(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
        onDidReceiveBackgroundNotificationResponse: captureAny(
          named: 'onDidReceiveBackgroundNotificationResponse',
        ),
      ),
    ).captured.single;
    expect(handler, isNotNull);
  });
}
