import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medaid/app/router/app_router.dart';
import 'package:medaid/app/router/app_routes.dart';
import 'package:medaid/core/location/location_service.dart';
import 'package:medaid/core/theme/app_theme.dart';
import 'package:medaid/core/widgets/buttons/emergency_button.dart';
import 'package:medaid/core/widgets/map/location_map.dart';

import '../../helpers/fake_location.dart';
import '../../helpers/fakes.dart';
import '../../helpers/user_app.dart';

Map<String, Object?> emergencyJson({
  String id = 'e1',
  String status = 'CREATED',
  bool withLocation = true,
  Map<String, Object?>? responder,
}) => {
  'id': id,
  'alertNumber': 'MED-20260917-0001',
  'status': status,
  'isOpen': !['RESOLVED', 'CANCELLED', 'EXPIRED'].contains(status),
  'location': withLocation ? {'latitude': 20.0086, 'longitude': 73.7925} : null,
  'createdAt': DateTime.now().toUtc().toIso8601String(),
  'timeline': [
    {'status': 'CREATED', 'at': DateTime.now().toUtc().toIso8601String()},
    if (status != 'CREATED') {'status': status, 'at': DateTime.now().toUtc().toIso8601String()},
  ],
  'responder': responder,
};

void main() {
  group('User home', () {
    testWidgets('shows the SOS button and quick actions', (tester) async {
      await pumpSignedInApp(tester);

      expect(find.byType(EmergencyButton), findsOneWidget);
      expect(find.text('Check symptoms'), findsOneWidget);
      expect(find.text('Hospitals & camps'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('surfaces an open emergency', (tester) async {
      await pumpSignedInApp(
        tester,
        respond: (r) async => r.path.endsWith('/emergencies/my')
            ? FakeResponse.ok({
                'items': [emergencyJson(status: 'ASSIGNING')],
                'page': 1,
                'limit': 1,
                'total': 1,
              })
            : FakeResponse.ok(null),
      );

      expect(find.text('You have an active alert'), findsOneWidget);
      expect(find.text('Finding a volunteer'), findsOneWidget);
    });
  });

  group('SOS flow', () {
    testWidgets('holding SOS sends location with an idempotency key and opens live status', (
      tester,
    ) async {
      final app = await pumpSignedInApp(
        tester,
        respond: (r) async {
          if (r.method == 'POST' && r.path.endsWith('/emergencies')) {
            return FakeResponse.ok(emergencyJson(), status: 201);
          }
          if (r.path.endsWith('/emergencies/e1')) return FakeResponse.ok(emergencyJson());
          return FakeResponse.ok(null);
        },
      );

      final gesture = await tester.startGesture(tester.getCenter(find.byType(EmergencyButton)));
      // Tap-down fires after the 100 ms press timeout and starts the hold
      // animation on the next frame; then the hold runs to completion.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(AppDurations.sosHold);
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.up();
      await tester.pumpAndSettle();

      final create = app.http.requests.firstWhere(
        (r) => r.method == 'POST' && r.path.endsWith('/emergencies'),
      );
      expect(create.data, containsPair('latitude', 20.0086));
      expect(create.headers['Idempotency-Key'], startsWith('sos-'));
      expect(find.text('Emergency alert'), findsOneWidget);
      expect(
        find.text(
          'We are finding the nearest available volunteer. Stay where you are if it is safe.',
        ),
        findsOneWidget,
      );
      await unmountApp(tester, app.container);
    });

    testWidgets('sends the alert even when location is denied (OQ-15)', (tester) async {
      final app = await pumpSignedInApp(
        tester,
        location: FakeLocationService(access: LocationAccess.denied),
        respond: (r) async {
          if (r.method == 'POST') {
            return FakeResponse.ok(emergencyJson(withLocation: false), status: 201);
          }
          if (r.path.endsWith('/emergencies/e1')) {
            return FakeResponse.ok(emergencyJson(withLocation: false));
          }
          return FakeResponse.ok(null);
        },
      );

      unawaited(app.container.read(routerProvider).push(AppRoutes.userSos));
      await tester.pumpAndSettle();

      final create = app.http.requests.firstWhere((r) => r.method == 'POST');
      expect((create.data! as Map).containsKey('latitude'), isFalse);
      expect(find.textContaining('could not get your location'), findsOneWidget);
      await unmountApp(tester, app.container);
    });

    testWidgets('a failed send can be retried with the same idempotency key', (tester) async {
      var attempts = 0;
      final app = await pumpSignedInApp(
        tester,
        respond: (r) async {
          if (r.method == 'POST') {
            attempts++;
            return attempts == 1 ? const FakeResponse.offline() : FakeResponse.ok(emergencyJson());
          }
          if (r.path.endsWith('/emergencies/e1')) return FakeResponse.ok(emergencyJson());
          return FakeResponse.ok(null);
        },
      );

      unawaited(app.container.read(routerProvider).push(AppRoutes.userSos));
      await tester.pumpAndSettle();
      expect(find.text('Alert not sent'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      final keys = app.http.requests
          .where((r) => r.method == 'POST')
          .map((r) => r.headers['Idempotency-Key'])
          .toSet();
      expect(keys, hasLength(1));
      expect(find.text('Emergency alert'), findsOneWidget);
      await unmountApp(tester, app.container);
    });
  });

  group('Emergency detail', () {
    testWidgets('shows the responder and ETA once a volunteer accepted', (tester) async {
      final app = await pumpSignedInApp(
        tester,
        respond: (r) async => r.path.endsWith('/emergencies/e1')
            ? FakeResponse.ok(
                emergencyJson(
                  status: 'ACCEPTED',
                  responder: {'name': 'Ravi', 'estimatedDurationSeconds': 250},
                ),
              )
            : FakeResponse.ok(null),
      );

      unawaited(app.container.read(routerProvider).push(AppRoutes.userEmergency('e1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Ravi accepted your alert and is coming to you.'), findsOneWidget);
      expect(find.text('About 5 min away'), findsOneWidget);
      await unmountApp(tester, app.container);
    });

    testWidgets('cancelling asks for confirmation and updates the status', (tester) async {
      var cancelled = false;
      final app = await pumpSignedInApp(
        tester,
        respond: (r) async {
          if (r.path.endsWith('/cancel')) {
            cancelled = true;
            return FakeResponse.ok(emergencyJson(status: 'CANCELLED'));
          }
          if (r.path.endsWith('/emergencies/e1')) {
            return FakeResponse.ok(emergencyJson(status: cancelled ? 'CANCELLED' : 'ASSIGNING'));
          }
          return FakeResponse.ok(null);
        },
      );

      unawaited(app.container.read(routerProvider).push(AppRoutes.userEmergency('e1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.ensureVisible(find.text('Cancel alert'));
      await tester.tap(find.text('Cancel alert'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel alert'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(cancelled, isTrue);
      expect(find.text('This alert was cancelled.'), findsOneWidget);
    });
  });

  group('Nearby facilities', () {
    Map<String, Object?> facility(String type, String name) => {
      'id': name,
      'type': type,
      'name': name,
      'location': {'latitude': 20.009, 'longitude': 73.793},
      'distanceMeters': 420,
      'services': ['First aid'],
      'contact': {'phone': '0253000000'},
      'endDateTime': DateTime.now().add(const Duration(hours: 5)).toUtc().toIso8601String(),
    };

    testWidgets('lists hospitals and camps near the device location', (tester) async {
      final app = await pumpSignedInApp(
        tester,
        respond: (r) async => r.path.endsWith('/facilities/nearby')
            ? FakeResponse.ok([
                facility('CAMP', 'Ghat Camp'),
                facility('HOSPITAL', 'City Hospital'),
              ])
            : FakeResponse.ok(null),
      );

      app.container.read(routerProvider).go(AppRoutes.userFacilities);
      await tester.pumpAndSettle();

      expect(find.text('Ghat Camp'), findsOneWidget);
      expect(find.text('City Hospital'), findsOneWidget);
      final request = app.http.requests.firstWhere((r) => r.path.endsWith('/facilities/nearby'));
      expect(request.queryParameters['latitude'], 20.0086);
    });

    testWidgets('still shows the map when nothing is nearby', (tester) async {
      final app = await pumpSignedInApp(
        tester,
        respond: (r) async => r.path.endsWith('/facilities/nearby')
            ? FakeResponse.ok(<Object>[])
            : FakeResponse.ok(null),
      );

      app.container.read(routerProvider).go(AppRoutes.userFacilities);
      await tester.pumpAndSettle();

      expect(find.byType(LocationMap), findsOneWidget);
      expect(find.textContaining('Try another filter'), findsOneWidget);
      await unmountApp(tester, app.container);
    });

    testWidgets('asks for location permission instead of failing', (tester) async {
      final app = await pumpSignedInApp(
        tester,
        location: FakeLocationService(access: LocationAccess.denied),
      );

      app.container.read(routerProvider).go(AppRoutes.userFacilities);
      await tester.pumpAndSettle();

      expect(find.text('Allow location access'), findsOneWidget);
      expect(app.http.requests.where((r) => r.path.endsWith('/facilities/nearby')), isEmpty);
    });
  });

  group('Symptom checker', () {
    testWidgets('selects symptoms, submits and shows emergency guidance', (tester) async {
      final app = await pumpSignedInApp(
        tester,
        respond: (r) async {
          if (r.path.endsWith('/symptoms')) {
            return FakeResponse.ok({
              'categories': [
                {
                  'key': 'breathing_chest',
                  'name': 'Breathing & chest',
                  'symptoms': [
                    {'key': 'chest_pain', 'name': 'Chest pain or pressure'},
                  ],
                },
              ],
            });
          }
          if (r.path.endsWith('/symptoms/check')) {
            return FakeResponse.ok({
              'level': 'EMERGENCY',
              'title': 'Get emergency help now',
              'message': 'These symptoms can be serious.',
              'advice': ['Stay where you are if it is safe.'],
              'firstAid': [
                'Help them sit down and rest. Do not let them walk about.',
                'Loosen tight clothing and keep the area around them clear.',
              ],
              'actions': ['SOS', 'CALL_EMERGENCY'],
              'warningSigns': ['Chest pain'],
              'redFlags': ['Chest pain or pressure'],
              'selectedSymptoms': [
                {'key': 'chest_pain', 'name': 'Chest pain or pressure'},
              ],
              'disclaimer': 'This is general guidance, not a medical diagnosis.',
            });
          }
          return FakeResponse.ok(null);
        },
      );

      unawaited(app.container.read(routerProvider).push(AppRoutes.userSymptoms));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chest pain or pressure'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('symptoms.submit')));
      await tester.pumpAndSettle();

      final check = app.http.requests.firstWhere((r) => r.path.endsWith('/symptoms/check'));
      expect(check.data, containsPair('symptoms', ['chest_pain']));
      expect(find.text('Get emergency help now'), findsOneWidget);
      expect(find.text('Send SOS alert'), findsOneWidget);
      expect(find.text('This is general guidance, not a medical diagnosis.'), findsOneWidget);
      expect(find.text('First aid you can give now'), findsOneWidget);
      expect(find.text('Help them sit down and rest. Do not let them walk about.'), findsOneWidget);
    });
  });

  group('leaving the app', () {
    testWidgets('back returns to the first tab before offering to leave', (tester) async {
      final app = await pumpSignedInApp(tester);
      app.container.read(routerProvider).go(AppRoutes.userFacilities);
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Back on a tab means "go home", not "leave".
      expect(find.byType(AlertDialog), findsNothing);
      expect(app.container.read(routerProvider).state.matchedLocation, AppRoutes.userHome);
      await unmountApp(tester, app.container);
    });

    testWidgets('asks before leaving from the first tab', (tester) async {
      final popped = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
        call,
      ) async {
        if (call.method == 'SystemNavigator.pop') popped.add(call.method);
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final app = await pumpSignedInApp(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Leave MedAID?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(popped, isEmpty);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      expect(popped, ['SystemNavigator.pop']);
      await unmountApp(tester, app.container);
    });
  });

  testWidgets('users cannot open another role area', (tester) async {
    final app = await pumpSignedInApp(tester);

    app.container.read(routerProvider).go(AppRoutes.adminHome);
    await tester.pumpAndSettle();

    final location = app.container
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .uri
        .path;
    expect(location, AppRoutes.userHome);
  });
}
