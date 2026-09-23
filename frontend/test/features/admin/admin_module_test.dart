import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medaid/app/router/app_router.dart';
import 'package:medaid/app/router/app_routes.dart';
import 'package:medaid/core/theme/app_theme.dart';
import 'package:medaid/core/widgets/map/location_map.dart';
import 'package:medaid/core/widgets/map/map_marker.dart';

import '../../helpers/fakes.dart';
import '../../helpers/user_app.dart';

Map<String, Object?> dashboardJson() => {
  'emergencies': {'open': 3, 'unassigned': 1, 'awaitingAcceptance': 1, 'inProgress': 1, 'today': 7},
  'volunteers': {
    'pendingVerification': 2,
    'byStatus': {'ACTIVE': 5, 'BUSY': 1, 'OFFLINE': 4},
  },
  'camps': {'activeNow': 4},
  'recentOpenEmergencies': [
    {
      'id': 'e1',
      'alertNumber': 'MED-20260917-0003',
      'status': 'UNASSIGNED',
      'isOpen': true,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'timeline': <Object>[],
      'attemptCount': 2,
      'reporter': {'name': 'Asha Patil'},
    },
  ],
};

Map<String, Object?> volunteerJson({String verificationStatus = 'PENDING'}) => {
  'id': 'v9',
  'user': {'id': 'u9', 'name': 'Meera Joshi', 'email': 'meera@example.com', 'username': 'meera'},
  'profile': {'phone': '+91 98220 00000', 'city': 'Nashik'},
  'profileCompleted': true,
  'verificationStatus': verificationStatus,
  'status': 'OFFLINE',
  'requiredDocuments': ['ID_PROOF', 'FIRST_AID_CERTIFICATE'],
  'documents': <Object>[],
};

void main() {
  testWidgets('dashboard shows live counts and open emergencies', (tester) async {
    final app = await pumpSignedInApp(
      tester,
      role: 'ADMIN',
      respond: (r) async => r.path.endsWith('/admin/dashboard')
          ? FakeResponse.ok(dashboardJson())
          : FakeResponse.ok(null),
    );

    expect(find.text('Control room'), findsOneWidget);
    expect(find.text('Waiting for a volunteer'), findsWidgets);
    expect(find.text('MED-20260917-0003'), findsOneWidget);
    expect(find.text('Attempts: 2'), findsOneWidget);
    await unmountApp(tester, app.container);
  });

  testWidgets('creating a volunteer shows the temporary password once', (tester) async {
    final app = await pumpSignedInApp(
      tester,
      role: 'ADMIN',
      respond: (r) async {
        if (r.method == 'POST' && r.path.endsWith('/admin/volunteers')) {
          return FakeResponse.ok({
            'volunteer': volunteerJson(verificationStatus: 'NOT_SUBMITTED'),
            'temporaryPassword': 'Kx7mPq2Rt9Lw',
          }, status: 201);
        }
        if (r.path.endsWith('/admin/volunteers')) {
          return FakeResponse.ok({'items': <Object>[], 'page': 1, 'limit': 50, 'total': 0});
        }
        if (r.path.endsWith('/admin/dashboard')) return FakeResponse.ok(dashboardJson());
        return FakeResponse.ok(null);
      },
    );

    unawaited(app.container.read(routerProvider).push(AppRoutes.adminVolunteerCreate));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('createVolunteer.name')).last, 'Meera Joshi');
    await tester.enterText(
      find.byKey(const Key('createVolunteer.email')).last,
      'meera@example.com',
    );
    await tester.enterText(find.byKey(const Key('createVolunteer.username')).last, 'meera');
    await tester.tap(find.byKey(const Key('createVolunteer.submit')));
    await tester.pumpAndSettle();

    final create = app.http.requests.firstWhere((r) => r.method == 'POST');
    expect(create.data, containsPair('username', 'meera'));
    expect(find.text('Kx7mPq2Rt9Lw'), findsOneWidget);
    expect(find.textContaining('It will not be shown again'), findsOneWidget);
    await unmountApp(tester, app.container);
  });

  testWidgets('approving a pending volunteer calls verify', (tester) async {
    var status = 'PENDING';
    final app = await pumpSignedInApp(
      tester,
      role: 'ADMIN',
      respond: (r) async {
        if (r.path.endsWith('/verify')) status = 'APPROVED';
        if (r.path.endsWith('/documents')) return FakeResponse.ok(<Object>[]);
        if (r.path.contains('/admin/volunteers/v9')) {
          return FakeResponse.ok(volunteerJson(verificationStatus: status));
        }
        if (r.path.endsWith('/admin/dashboard')) return FakeResponse.ok(dashboardJson());
        return FakeResponse.ok(null);
      },
    );

    unawaited(app.container.read(routerProvider).push(AppRoutes.adminVolunteer('v9')));
    await tester.pumpAndSettle();
    expect(find.text('Under review'), findsWidgets);

    await tester.tap(find.byKey(const Key('admin.approve')));
    await tester.pumpAndSettle();

    expect(app.http.requests.where((r) => r.path.endsWith('/v9/verify')), hasLength(1));
    expect(find.text('Verified'), findsOneWidget);
    expect(find.byKey(const Key('admin.approve')), findsNothing);
    await unmountApp(tester, app.container);
  });

  testWidgets('a camp cannot be saved without a location, then saves with a tapped one', (
    tester,
  ) async {
    final app = await pumpSignedInApp(
      tester,
      role: 'ADMIN',
      respond: (r) async {
        if (r.method == 'POST' && r.path.endsWith('/admin/medical-camps')) {
          return FakeResponse.ok({'id': 'c1', 'name': 'Ghat Camp'}, status: 201);
        }
        if (r.path.endsWith('/admin/medical-camps')) {
          return FakeResponse.ok({'items': <Object>[], 'page': 1, 'limit': 100, 'total': 0});
        }
        if (r.path.endsWith('/admin/dashboard')) return FakeResponse.ok(dashboardJson());
        return FakeResponse.ok(null);
      },
    );

    unawaited(app.container.read(routerProvider).push(AppRoutes.adminCampCreate));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ghat Camp');
    await tester.enterText(fields.at(2), 'Ramkund');

    // The form is a lazy ListView: scroll widgets into existence before tapping.
    final form = find
        .ancestor(of: find.byType(TextFormField).first, matching: find.byType(Scrollable))
        .first;
    final save = find.text('Save');
    await tester.scrollUntilVisible(save, 200, scrollable: form);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Choose the camp location on the map.'), findsOneWidget);
    // Let the snackbar expire; it overlays the Save button at the bottom.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.byType(LocationMap), -200, scrollable: form);
    await tester.tapAt(tester.getCenter(find.byType(LocationMap)));
    // flutter_map reports a single tap after the double-tap timeout.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(MapMarker), findsOneWidget);

    await tester.scrollUntilVisible(save, 200, scrollable: form);
    await tester.tap(save);
    await tester.pumpAndSettle();

    final create = app.http.requests.firstWhere((r) => r.method == 'POST');
    expect(create.data, containsPair('name', 'Ghat Camp'));
    expect((create.data! as Map).containsKey('latitude'), isTrue);
    await unmountApp(tester, app.container);
  });

  group('document viewer', () {
    Future<ProviderContainer> openDocuments(WidgetTester tester, String mimeType) async {
      final app = await pumpSignedInApp(
        tester,
        role: 'ADMIN',
        respond: (r) async {
          if (r.path.endsWith('/documents')) {
            return FakeResponse.ok([
              {
                'id': 'd1',
                'documentType': 'ID_PROOF',
                'status': 'PENDING',
                'uploadedAt': DateTime.now().toUtc().toIso8601String(),
                'mimeType': mimeType,
                'url': 'https://res.cloudinary.test/signed/id-proof',
              },
            ]);
          }
          if (r.path.contains('/admin/volunteers/v9')) {
            return FakeResponse.ok(volunteerJson(verificationStatus: 'PENDING'));
          }
          if (r.path.endsWith('/admin/dashboard')) return FakeResponse.ok(dashboardJson());
          return FakeResponse.ok(null);
        },
      );

      unawaited(app.container.read(routerProvider).push(AppRoutes.adminVolunteer('v9')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin.viewDocument')));
      await tester.pumpAndSettle();
      return app.container;
    }

    testWidgets('shows an image document inside the app', (tester) async {
      final container = await openDocuments(tester, 'image/jpeg');

      // Stays in the app rather than handing the signed link to a browser.
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
      expect(find.byKey(const Key('admin.openDocumentExternally')), findsNothing);
      expect(
        container.read(routerProvider).state.matchedLocation,
        AppRoutes.adminVolunteerDocument('v9'),
      );
      await unmountApp(tester, container);
    });

    testWidgets('a PDF explains itself and offers to open outside', (tester) async {
      final container = await openDocuments(tester, 'application/pdf');

      expect(find.textContaining('This is a PDF'), findsOneWidget);
      expect(find.byKey(const Key('admin.openDocumentExternally')), findsOneWidget);
      await unmountApp(tester, container);
    });

    testWidgets('opened directly, it says where to find documents', (tester) async {
      final app = await pumpSignedInApp(
        tester,
        role: 'ADMIN',
        respond: (r) async => r.path.endsWith('/admin/dashboard')
            ? FakeResponse.ok(dashboardJson())
            : FakeResponse.ok(null),
      );

      unawaited(app.container.read(routerProvider).push(AppRoutes.adminVolunteerDocument('v9')));
      await tester.pumpAndSettle();

      expect(find.text('Nothing to show'), findsOneWidget);
      await unmountApp(tester, app.container);
    });
  });

  testWidgets('tracking map counts volunteers by state and greys out stale positions', (
    tester,
  ) async {
    Map<String, Object?> pin(String id, String status, {bool stale = false}) => {
      'volunteerId': id,
      'name': 'Volunteer $id',
      'status': status,
      'currentEmergencyId': null,
      'location': {'latitude': 20.0086, 'longitude': 73.7925, 'isStale': stale},
    };
    final app = await pumpSignedInApp(
      tester,
      role: 'ADMIN',
      respond: (r) async {
        if (r.path.endsWith('/admin/volunteers/locations')) {
          return FakeResponse.ok([
            pin('a', 'ACTIVE'),
            pin('b', 'ACTIVE'),
            pin('c', 'BUSY'),
            pin('d', 'ACTIVE', stale: true),
          ]);
        }
        if (r.path.endsWith('/admin/dashboard')) return FakeResponse.ok(dashboardJson());
        return FakeResponse.ok(null);
      },
    );

    unawaited(app.container.read(routerProvider).push(AppRoutes.adminTracking));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('2 available'), findsOneWidget);
    expect(find.text('1 responding'), findsOneWidget);
    expect(find.text('1 location out of date'), findsOneWidget);
    final markers = tester.widget<LocationMap>(find.byType(LocationMap)).markers;
    expect(markers.firstWhere((m) => m.id == 'd').tone, AppTone.neutral);
    expect(markers.firstWhere((m) => m.id == 'c').tone, AppTone.info);
    await unmountApp(tester, app.container);
  });
}
