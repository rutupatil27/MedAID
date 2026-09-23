import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medaid/app/router/app_router.dart';
import 'package:medaid/app/router/app_routes.dart';
import 'package:medaid/core/notifications/push_service.dart';
import 'package:medaid/features/auth/application/auth_controller.dart';
import 'package:medaid/features/notifications/application/notification_links.dart';
import 'package:medaid/shared/enums/user_role.dart';

import '../../helpers/fake_push.dart';
import '../../helpers/fakes.dart';
import '../../helpers/user_app.dart';

const emergencyId = '507f1f77bcf86cd799439011';
const volunteerId = '507f191e810c19729de860ea';

Map<String, Object?> notificationJson({
  String id = 'n1',
  String type = 'EMERGENCY_ACCEPTED',
  String title = 'Help is on the way',
  bool isRead = false,
  Map<String, String> data = const {'emergencyId': emergencyId},
}) => {
  'id': id,
  'type': type,
  'title': title,
  'body': 'A volunteer accepted your alert and is coming to you.',
  'data': data,
  'isRead': isRead,
  'createdAt': DateTime.now().toUtc().toIso8601String(),
};

Map<String, Object?> pageJson(List<Map<String, Object?>> items) => {
  'items': items,
  'page': 1,
  'limit': 50,
  'total': items.length,
  'unreadCount': items.where((n) => n['isRead'] != true).length,
};

/// The top page, including imperatively pushed ones.
String location(ProviderContainer container) =>
    container.read(routerProvider).state.matchedLocation;

/// Lets requests finish: Dio schedules a zero-delay timer per request.
Future<void> settleRequests(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('deep links (doc 19: open only what the signed-in role may see)', () {
    test('each role goes to its own detail screens', () {
      expect(
        notificationRoute(
          role: UserRole.user,
          type: 'EMERGENCY_ACCEPTED',
          data: {'emergencyId': emergencyId},
        ),
        AppRoutes.userEmergency(emergencyId),
      );
      expect(
        notificationRoute(
          role: UserRole.volunteer,
          type: 'ASSIGNMENT_NEW',
          data: {'emergencyId': emergencyId},
        ),
        AppRoutes.volunteerEmergency(emergencyId),
      );
      expect(
        notificationRoute(role: UserRole.volunteer, type: 'VERIFICATION_REJECTED', data: {}),
        AppRoutes.volunteerVerification,
      );
      expect(
        notificationRoute(
          role: UserRole.admin,
          type: 'VERIFICATION_SUBMITTED',
          data: {'volunteerId': volunteerId},
        ),
        AppRoutes.adminVolunteer(volunteerId),
      );
      expect(
        notificationRoute(
          role: UserRole.admin,
          type: 'EMERGENCY_UNASSIGNED',
          data: {'emergencyId': emergencyId},
        ),
        AppRoutes.adminEmergency(emergencyId),
      );
    });

    test('never leaves the role\'s own area, whatever the payload says', () {
      const types = [
        'EMERGENCY_CREATED',
        'EMERGENCY_ACCEPTED',
        'EMERGENCY_UNASSIGNED',
        'ASSIGNMENT_NEW',
        'ASSIGNMENT_EXPIRED',
        'VERIFICATION_SUBMITTED',
        'VERIFICATION_APPROVED',
        'ADMIN_NOTICE',
        'SOMETHING_NEW',
      ];
      for (final role in UserRole.values) {
        for (final type in types) {
          final route = notificationRoute(
            role: role,
            type: type,
            data: {'emergencyId': emergencyId, 'volunteerId': volunteerId},
          );
          if (route != null) expect(route, startsWith(AppRoutes.homeFor(role)));
        }
      }
    });

    test('rejects malformed IDs', () {
      for (final id in ['../admin', 'abc', '507f1f77bcf86cd79943901', '507F1F77BCF86CD799439011']) {
        expect(
          notificationRoute(
            role: UserRole.user,
            type: 'EMERGENCY_ACCEPTED',
            data: {'emergencyId': id},
          ),
          isNull,
        );
      }
    });

    test('events without a screen stay in the notification center', () {
      expect(notificationRoute(role: UserRole.volunteer, type: 'ADMIN_NOTICE', data: {}), isNull);
      expect(notificationRoute(role: UserRole.user, type: 'EMERGENCY_ACCEPTED', data: {}), isNull);
    });
  });

  group('notification center', () {
    testWidgets('the bell shows the unread count and opens a notification', (tester) async {
      var read = false;
      final app = await pumpSignedInApp(
        tester,
        respond: (r) async {
          if (r.path.endsWith('/notifications/unread-count')) {
            return FakeResponse.ok({'unreadCount': read ? 0 : 1});
          }
          if (r.path.endsWith('/notifications')) {
            return FakeResponse.ok(pageJson([notificationJson(isRead: read)]));
          }
          if (r.path.endsWith('/notifications/n1/read')) {
            read = true;
            return FakeResponse.ok(notificationJson(isRead: true));
          }
          return FakeResponse.ok(null);
        },
      );

      final bell = find.byKey(const Key('notifications.bell'));
      expect(find.descendant(of: bell, matching: find.text('1')), findsOneWidget);

      await tester.tap(bell);
      await tester.pumpAndSettle();
      expect(find.text('Help is on the way'), findsOneWidget);
      expect(find.byKey(const Key('notification.unreadDot')), findsOneWidget);

      await tester.tap(find.text('Help is on the way'));
      await tester.pumpAndSettle();

      expect(
        app.http.requests.where((r) => r.method == 'PATCH' && r.path.endsWith('/n1/read')),
        hasLength(1),
      );
      expect(location(app.container), AppRoutes.userEmergency(emergencyId));
      await unmountApp(tester, app.container);
    });

    testWidgets('mark all read', (tester) async {
      var read = false;
      final app = await pumpSignedInApp(
        tester,
        respond: (r) async {
          if (r.path.endsWith('/notifications/read-all')) {
            read = true;
            return FakeResponse.ok({'updated': 2});
          }
          if (r.path.endsWith('/notifications')) {
            return FakeResponse.ok(
              pageJson([
                notificationJson(isRead: read),
                notificationJson(
                  id: 'n2',
                  type: 'EMERGENCY_CREATED',
                  title: 'Alert sent',
                  isRead: read,
                ),
              ]),
            );
          }
          return FakeResponse.ok(null);
        },
      );

      unawaited(app.container.read(routerProvider).push(AppRoutes.notifications));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('notification.unreadDot')), findsNWidgets(2));

      await tester.tap(find.byKey(const Key('notifications.markAllRead')));
      await tester.pumpAndSettle();

      expect(app.http.requests.where((r) => r.path.endsWith('/read-all')), hasLength(1));
      expect(find.byKey(const Key('notification.unreadDot')), findsNothing);
      expect(find.byKey(const Key('notifications.markAllRead')), findsNothing);
      await unmountApp(tester, app.container);
    });

    testWidgets('an empty inbox explains itself', (tester) async {
      final app = await pumpSignedInApp(
        tester,
        role: 'ADMIN',
        respond: (r) async => r.path.endsWith('/notifications')
            ? FakeResponse.ok(pageJson([]))
            : FakeResponse.ok(null),
      );

      unawaited(app.container.read(routerProvider).push(AppRoutes.notifications));
      await tester.pumpAndSettle();

      expect(find.text('No notifications yet'), findsOneWidget);
      await unmountApp(tester, app.container);
    });
  });

  group('push', () {
    testWidgets('registers this device after sign-in and removes it before sign-out', (
      tester,
    ) async {
      final push = FakePushService();
      final app = await pumpSignedInApp(
        tester,
        overrides: [pushServiceProvider.overrideWithValue(push)],
      );

      final registration = app.http.requests.where(
        (r) => r.method == 'POST' && r.path == '/devices',
      );
      expect(registration.single.data, {'token': 'device-token-123', 'platform': 'android'});
      expect(push.permissionRequests, 1);

      unawaited(app.container.read(authProvider.notifier).logout());
      await settleRequests(tester);

      final calls = [for (final r in app.http.requests) '${r.method} ${r.path}'];
      final removed = calls.indexOf('DELETE /devices/device-token-123');
      final loggedOut = calls.indexWhere((c) => c.endsWith('/auth/logout'));
      expect(removed, isNonNegative);
      expect(removed, lessThan(loggedOut));
      await unmountApp(tester, app.container);
    });

    testWidgets('does not register while a password change is pending', (tester) async {
      final push = FakePushService();
      final app = await pumpSignedInApp(
        tester,
        overrides: [pushServiceProvider.overrideWithValue(push)],
        respond: (r) async => FakeResponse.ok(null),
        mustChangePassword: true,
      );

      expect(app.http.requests.where((r) => r.path == '/devices'), isEmpty);
      await unmountApp(tester, app.container);
    });

    testWidgets('tapping a push opens its screen and marks it read', (tester) async {
      final push = FakePushService();
      final app = await pumpSignedInApp(
        tester,
        overrides: [pushServiceProvider.overrideWithValue(push)],
      );

      push.opened.add(
        const PushMessage(
          data: {'type': 'EMERGENCY_ACCEPTED', 'emergencyId': emergencyId, 'notificationId': 'n7'},
        ),
      );
      await tester.pumpAndSettle();

      expect(location(app.container), AppRoutes.userEmergency(emergencyId));
      expect(
        app.http.requests.where((r) => r.path.endsWith('/notifications/n7/read')),
        hasLength(1),
      );
      await unmountApp(tester, app.container);
    });

    testWidgets('a push for another role opens the notification center instead', (tester) async {
      final push = FakePushService();
      final app = await pumpSignedInApp(
        tester,
        overrides: [pushServiceProvider.overrideWithValue(push)],
        respond: (r) async => r.path.endsWith('/notifications')
            ? FakeResponse.ok(pageJson([]))
            : FakeResponse.ok(null),
      );

      push.opened.add(
        const PushMessage(data: {'type': 'ASSIGNMENT_NEW', 'emergencyId': emergencyId}),
      );
      await tester.pumpAndSettle();

      expect(location(app.container), AppRoutes.notifications);
      await unmountApp(tester, app.container);
    });

    testWidgets('a push that launched the app opens once the session is restored', (tester) async {
      final push = FakePushService(
        initial: const PushMessage(
          data: {'type': 'EMERGENCY_RESOLVED', 'emergencyId': emergencyId},
        ),
      );
      final app = await pumpSignedInApp(
        tester,
        overrides: [pushServiceProvider.overrideWithValue(push)],
      );
      await tester.pumpAndSettle();

      expect(location(app.container), AppRoutes.userEmergency(emergencyId));
      await unmountApp(tester, app.container);
    });

    testWidgets('a push in the foreground refreshes the unread badge', (tester) async {
      final push = FakePushService();
      final app = await pumpSignedInApp(
        tester,
        overrides: [pushServiceProvider.overrideWithValue(push)],
      );
      final before = app.http.requests.where((r) => r.path.endsWith('/unread-count')).length;

      push.foreground.add(
        const PushMessage(
          data: {'type': 'EMERGENCY_ACCEPTED', 'emergencyId': emergencyId},
          title: 'Help is on the way',
        ),
      );
      await settleRequests(tester);

      // The app stays where it is; the bell shows the new count.
      expect(
        app.http.requests.where((r) => r.path.endsWith('/unread-count')).length,
        greaterThan(before),
      );
      expect(location(app.container), AppRoutes.userHome);
      await unmountApp(tester, app.container);
    });
  });

  group('admin notice', () {
    testWidgets('sends the typed message to volunteers', (tester) async {
      final app = await pumpSignedInApp(
        tester,
        role: 'ADMIN',
        respond: (r) async => r.path.endsWith('/admin/notices')
            ? FakeResponse.ok({'recipients': 3}, status: 201)
            : FakeResponse.ok(null),
      );

      unawaited(app.container.read(routerProvider).push(AppRoutes.adminMore));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin.sendNotice')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('noteSheet.field')).last, 'Ghat 4 is closed');
      await tester.tap(find.byKey(const Key('noteSheet.submit')));
      await tester.pumpAndSettle();

      final sent = app.http.requests.singleWhere((r) => r.path.endsWith('/admin/notices'));
      expect(sent.data, {'message': 'Ghat 4 is closed'});
      expect(find.text('Notice sent to 3 volunteers.'), findsOneWidget);
      await unmountApp(tester, app.container);
    });
  });
}
