import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medaid/app/router/app_router.dart';
import 'package:medaid/app/router/app_routes.dart';
import 'package:medaid/core/files/document_picker.dart';
import 'package:medaid/core/location/location_service.dart';
import 'package:medaid/core/notifications/alert_actions.dart';
import 'package:medaid/core/notifications/local_notifier.dart';

import '../../helpers/fake_location.dart';
import '../../helpers/fake_notifier.dart';
import '../../helpers/fakes.dart';
import '../../helpers/user_app.dart';
import '../../helpers/volunteer_fixtures.dart';

class FakePicker implements DocumentPicker {
  FakePicker(this.document);

  final PickedDocument document;

  @override
  Future<PickedDocument?> pick() async => document;
}

void main() {
  testWidgets('an unverified volunteer sees the onboarding steps', (tester) async {
    await pumpSignedInApp(
      tester,
      role: 'VOLUNTEER',
      respond: (r) async => r.path.endsWith('/volunteers/me')
          ? FakeResponse.ok(
              volunteerJson(verificationStatus: 'NOT_SUBMITTED', profileCompleted: false),
            )
          : FakeResponse.ok(null),
    );

    expect(find.text('Finish setting up'), findsOneWidget);
    expect(find.text('Complete your profile'), findsOneWidget);
    expect(find.text('Upload verification documents'), findsOneWidget);
    expect(find.text('Not submitted'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('going active sends the current location with the status change', (tester) async {
    var status = 'OFFLINE';
    final app = await pumpSignedInApp(
      tester,
      role: 'VOLUNTEER',
      respond: (r) async {
        if (r.path.endsWith('/volunteers/me/status')) {
          status = (r.data! as Map)['status'] as String;
          return FakeResponse.ok(volunteerJson(status: status));
        }
        if (r.path.endsWith('/volunteers/me')) {
          return FakeResponse.ok(volunteerJson(status: status));
        }
        if (r.path.endsWith('/volunteers/me/emergencies')) {
          return FakeResponse.ok({'items': <Object>[], 'page': 1, 'limit': 50, 'total': 0});
        }
        return FakeResponse.ok(null);
      },
    );

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final request = app.http.requests.firstWhere((r) => r.path.endsWith('/status'));
    expect(request.data, containsPair('status', 'ACTIVE'));
    expect(request.data, containsPair('latitude', 20.0086));
    expect(find.text('You will receive nearby emergencies.'), findsOneWidget);
    await unmountApp(tester, app.container);
  });

  testWidgets('going active without a location explains why it failed', (tester) async {
    final app = await pumpSignedInApp(
      tester,
      role: 'VOLUNTEER',
      location: FakeLocationService(access: LocationAccess.denied),
      respond: (r) async {
        if (r.path.endsWith('/volunteers/me')) return FakeResponse.ok(volunteerJson());
        if (r.path.endsWith('/volunteers/me/emergencies')) {
          return FakeResponse.ok({'items': <Object>[], 'page': 1, 'limit': 50, 'total': 0});
        }
        return FakeResponse.ok(null);
      },
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.textContaining('location is unavailable'), findsOneWidget);
    expect(app.http.requests.where((r) => r.path.endsWith('/status')), isEmpty);
    await unmountApp(tester, app.container);
  });

  testWidgets('accept, then resolve with a note', (tester) async {
    var emergency = dispatchedJson();
    final app = await pumpSignedInApp(
      tester,
      role: 'VOLUNTEER',
      respond: (r) async {
        if (r.path.endsWith('/accept')) {
          emergency = dispatchedJson(emergencyStatus: 'ACCEPTED', assignmentStatus: 'ACCEPTED');
        } else if (r.path.endsWith('/start')) {
          emergency = dispatchedJson(emergencyStatus: 'IN_PROGRESS', assignmentStatus: 'ACCEPTED');
        } else if (r.path.endsWith('/resolve')) {
          emergency = dispatchedJson(emergencyStatus: 'RESOLVED', assignmentStatus: 'COMPLETED');
        } else if (r.path.endsWith('/volunteers/me')) {
          return FakeResponse.ok(volunteerJson(status: 'ACTIVE'));
        } else if (r.path.endsWith('/volunteers/me/emergencies')) {
          return FakeResponse.ok({'items': <Object>[], 'page': 1, 'limit': 50, 'total': 0});
        } else if (!r.path.endsWith('/emergencies/e1')) {
          return FakeResponse.ok(null);
        }
        return FakeResponse.ok(emergency);
      },
    );

    unawaited(app.container.read(routerProvider).push(AppRoutes.volunteerEmergency('e1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Asha Patil'), findsOneWidget);
    expect(find.textContaining('Penicillin'), findsOneWidget);

    await tester.tap(find.byKey(const Key('volunteer.accept')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('I have arrived'), findsOneWidget);

    await tester.tap(find.text('I have arrived'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('volunteer.resolve')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('noteSheet.field')).last, 'First aid given');
    await tester.tap(find.byKey(const Key('noteSheet.submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final resolve = app.http.requests.firstWhere((r) => r.path.endsWith('/resolve'));
    expect(resolve.data, {'resolutionNote': 'First aid given'});
    expect(find.text('This emergency is closed.'), findsOneWidget);
    await unmountApp(tester, app.container);
  });

  group('emergency alerts', () {
    Future<
      ({FakeLocalNotifier notifier, ProviderContainer container, List<RequestOptions> requests})
    >
    onDuty(WidgetTester tester, {required List<Map<String, Object?>> assignments}) async {
      var current = assignments;
      final app = await pumpSignedInApp(
        tester,
        role: 'VOLUNTEER',
        respond: (r) async {
          if (r.path.endsWith('/volunteers/me')) {
            return FakeResponse.ok(volunteerJson(status: 'ACTIVE'));
          }
          // Answered: the server stops offering it, as the real one does.
          if (r.path.endsWith('/accept') || r.path.endsWith('/decline')) {
            current = const [];
            return FakeResponse.ok(dispatchedJson(assignmentStatus: 'ACCEPTED'));
          }
          if (r.path.endsWith('/volunteers/me/emergencies')) {
            return FakeResponse.ok({
              'items': current,
              'page': 1,
              'limit': 50,
              'total': current.length,
            });
          }
          return FakeResponse.ok(null);
        },
      );
      await tester.pump(const Duration(milliseconds: 100));
      return (notifier: app.notifier, container: app.container, requests: app.http.requests);
    }

    testWidgets('a new assignment raises one system notification', (tester) async {
      final app = await onDuty(tester, assignments: [dispatchedJson()]);

      expect(app.notifier.shown, hasLength(1));
      expect(app.notifier.shown.single.title, 'New emergency near you');
      expect(app.notifier.shown.single.payload, 'e1');
      expect(app.notifier.permissionRequests, greaterThan(0));

      // Polling repeats the same assignment: no second ping.
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(milliseconds: 100));
      expect(app.notifier.shown, hasLength(1));
      await unmountApp(tester, app.container);
    });

    testWidgets('no notification when nothing is waiting for an answer', (tester) async {
      final app = await onDuty(
        tester,
        assignments: [dispatchedJson(emergencyStatus: 'ACCEPTED', assignmentStatus: 'ACCEPTED')],
      );

      expect(app.notifier.shown, isEmpty);
      await unmountApp(tester, app.container);
    });

    testWidgets('keeps ringing until the emergency is answered', (tester) async {
      final app = await onDuty(tester, assignments: [dispatchedJson()]);
      expect(app.notifier.shown, hasLength(1));

      // One beep in a crowd is easy to miss, so it rings again.
      await tester.pump(const Duration(seconds: 16));
      await tester.pump(const Duration(milliseconds: 100));
      expect(app.notifier.shown.length, greaterThan(1));
      expect(app.notifier.shown.every((a) => a.ongoing), isTrue);

      final rings = app.notifier.shown.length;
      app.notifier.responses.add(const AlertResponse(payload: 'e1', actionId: declineAction));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 30));
      await tester.pump(const Duration(milliseconds: 100));

      expect(app.notifier.shown, hasLength(rings));
      expect(app.notifier.cancelled, isNotEmpty);
      await unmountApp(tester, app.container);
    });

    testWidgets('offers Accept and Decline on the notification itself', (tester) async {
      final app = await onDuty(tester, assignments: [dispatchedJson()]);

      expect(app.notifier.shown.single.actions.map((a) => a.id), [acceptAction, declineAction]);
      expect(app.notifier.shown.single.actions.map((a) => a.label), [
        'Accept emergency',
        'Decline',
      ]);
      await unmountApp(tester, app.container);
    });

    testWidgets('Accept and Decline answer without opening the app first', (tester) async {
      for (final (action, path) in [(acceptAction, '/accept'), (declineAction, '/decline')]) {
        final app = await onDuty(tester, assignments: [dispatchedJson()]);

        app.notifier.responses.add(AlertResponse(payload: 'e1', actionId: action));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        final calls = app.requests.where((r) => r.path.endsWith('/emergencies/e1$path'));
        expect(calls, hasLength(1), reason: 'expected a call to $path');
        await unmountApp(tester, app.container);
      }
    });

    testWidgets('tapping the notification opens the emergency', (tester) async {
      final app = await onDuty(tester, assignments: [dispatchedJson()]);

      app.notifier.responses.add(const AlertResponse(payload: 'e1'));
      await tester.pumpAndSettle();

      expect(
        app.container.read(routerProvider).state.matchedLocation,
        AppRoutes.volunteerEmergency('e1'),
      );
      await unmountApp(tester, app.container);
    });
  });

  testWidgets('uploads a picked document as multipart form data', (tester) async {
    final picked = PickedDocument(
      name: 'id.png',
      bytes: Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    );
    final app = await pumpSignedInApp(
      tester,
      role: 'VOLUNTEER',
      overrides: [documentPickerProvider.overrideWithValue(FakePicker(picked))],
      respond: (r) async {
        if (r.path.endsWith('/documents')) {
          return FakeResponse.ok({'verificationStatus': 'NOT_SUBMITTED'}, status: 201);
        }
        if (r.path.endsWith('/volunteers/me')) {
          return FakeResponse.ok(volunteerJson(verificationStatus: 'NOT_SUBMITTED'));
        }
        return FakeResponse.ok(null);
      },
    );

    unawaited(app.container.read(routerProvider).push(AppRoutes.volunteerDocuments));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload').first);
    await tester.pumpAndSettle();

    final upload = app.http.requests.firstWhere((r) => r.path.endsWith('/documents'));
    final form = upload.data! as FormData;
    expect(form.fields.map((e) => '${e.key}=${e.value}'), contains('documentType=ID_PROOF'));
    expect(form.files.single.value.filename, 'id.png');
    expect(find.text('Document uploaded.'), findsOneWidget);
  });

  testWidgets('rejects files over 5 MB before uploading', (tester) async {
    final picked = PickedDocument(name: 'big.pdf', bytes: Uint8List(5 * 1024 * 1024 + 1));
    final app = await pumpSignedInApp(
      tester,
      role: 'VOLUNTEER',
      overrides: [documentPickerProvider.overrideWithValue(FakePicker(picked))],
      respond: (r) async => r.path.endsWith('/volunteers/me')
          ? FakeResponse.ok(volunteerJson(verificationStatus: 'NOT_SUBMITTED'))
          : FakeResponse.ok(null),
    );

    unawaited(app.container.read(routerProvider).push(AppRoutes.volunteerDocuments));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('larger than 5 MB'), findsOneWidget);
    expect(app.http.requests.where((r) => r.path.endsWith('/documents')), isEmpty);
  });
}
