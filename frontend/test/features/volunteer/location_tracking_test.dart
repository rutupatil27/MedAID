import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medaid/app/router/app_router.dart';
import 'package:medaid/app/router/app_routes.dart';
import 'package:medaid/core/location/location_service.dart';
import 'package:medaid/core/network/network_providers.dart';
import 'package:medaid/core/storage/preferences_storage.dart';
import 'package:medaid/features/volunteer/application/location_tracking_controller.dart';
import 'package:medaid/features/volunteer/application/volunteer_controller.dart';
import 'package:medaid/shared/models/geo_point.dart';

import '../../helpers/fake_location.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';
import '../../helpers/user_app.dart';
import '../../helpers/volunteer_fixtures.dart';

LocationFix fixAt(double latitude) => LocationFix(
  point: GeoPoint(latitude: latitude, longitude: 73.7925),
  accuracyMeters: 8,
  timestamp: DateTime(2026, 9, 19, 10),
);

/// The tracking controller against a scripted backend, without any UI.
class _Tracking {
  _Tracking(this.tester, this.volunteerStatus, this.verificationStatus, this.location);

  final WidgetTester tester;

  String volunteerStatus;
  final String verificationStatus;
  final FakeLocationService location;
  FakeResponse locationResponse = FakeResponse.ok({'location': null});
  late final FakeHttpAdapter http;
  late final ProviderContainer container;

  List<Object?> get sent => [
    for (final r in http.requests)
      if (r.path.endsWith('/volunteers/me/location')) (r.data as Map)['latitude'],
  ];

  LocationTrackingState get state => container.read(locationTrackingProvider);

  static Future<_Tracking> start(
    WidgetTester tester, {
    String status = 'ACTIVE',
    String verificationStatus = 'APPROVED',
    FakeLocationService? location,
  }) async {
    final t = _Tracking(tester, status, verificationStatus, location ?? FakeLocationService());
    t.http = FakeHttpAdapter((options) async {
      if (options.path.endsWith('/volunteers/me/location')) return t.locationResponse;
      if (options.path.endsWith('/volunteers/me')) {
        return FakeResponse.ok(
          volunteerJson(status: t.volunteerStatus, verificationStatus: t.verificationStatus),
        );
      }
      return FakeResponse.ok(null);
    });
    t.container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        preferencesStorageProvider.overrideWithValue(await fakePreferences()),
        dioProvider.overrideWithValue(fakeDio(t.http)),
        locationServiceProvider.overrideWithValue(t.location),
      ],
    );
    addTearDown(t.container.dispose);
    t.container.listen(locationTrackingProvider, (_, _) {});
    await t.settle();
    return t;
  }

  /// Lets queued async work finish on the test clock without advancing it.
  Future<void> settle() => _settle(tester);

  /// Stops tracking timers before the test framework checks for pending ones.
  void end() => container.dispose();

  Future<void> goOffline() async {
    volunteerStatus = 'OFFLINE';
    unawaited(container.read(volunteerProvider.notifier).refresh());
    await settle();
  }
}

/// Runs microtasks and zero-delay timers (Dio schedules one per request).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(Duration.zero);
  }
}

Future<void> elapse(WidgetTester tester, Duration duration) async {
  await tester.pump(duration);
  await _settle(tester);
}

void main() {
  group('location tracking lifecycle', () {
    testWidgets('reports at once, coalesces movement, and keeps a stationary volunteer fresh', (
      tester,
    ) async {
      final t = await _Tracking.start(tester);

      expect(t.state.status, TrackingStatus.tracking);
      expect(t.sent, [20.0086]); // immediate report
      expect(t.state.lastSentAt, isNotNull);

      // Two moves inside the 10 s gap: only the latest is sent.
      t.location.updates
        ..add(fixAt(20.0090))
        ..add(fixAt(20.0095));
      await t.settle();
      expect(t.sent, hasLength(1));
      await elapse(tester, const Duration(seconds: 10));
      expect(t.sent, [20.0086, 20.0095]);

      await elapse(tester, const Duration(seconds: 11));
      t.location.updates.add(fixAt(20.0100));
      await t.settle();
      expect(t.sent.last, 20.0100);

      // Moved since the first beat, so it is skipped; the next one reports.
      await elapse(tester, const Duration(seconds: 40));
      expect(t.sent, hasLength(3));
      await elapse(tester, const Duration(seconds: 60));
      expect(t.sent, hasLength(4));
      expect(t.state.lastFix?.point.latitude, 20.0086);
      t.end();
    });

    testWidgets('stops as soon as the volunteer goes OFFLINE', (tester) async {
      final t = await _Tracking.start(tester);
      expect(t.location.updates.hasListener, isTrue);

      await t.goOffline();

      expect(t.state.status, TrackingStatus.off);
      expect(t.location.updates.hasListener, isFalse);
      final sent = t.sent.length;
      await elapse(tester, const Duration(minutes: 5));
      expect(t.sent, hasLength(sent));
    });

    testWidgets('never tracks an OFFLINE or unverified volunteer', (tester) async {
      final offline = await _Tracking.start(tester, status: 'OFFLINE');
      final unverified = await _Tracking.start(tester, verificationStatus: 'PENDING');
      await elapse(tester, const Duration(minutes: 2));

      for (final t in [offline, unverified]) {
        expect(t.state.status, TrackingStatus.off);
        expect(t.location.updates.hasListener, isFalse);
        expect(t.sent, isEmpty);
      }
    });

    testWidgets('explains missing permission and resumes once it is granted', (tester) async {
      final t = await _Tracking.start(
        tester,
        location: FakeLocationService(access: LocationAccess.denied),
      );

      expect(t.state.status, TrackingStatus.unavailable);
      expect(t.state.access, LocationAccess.denied);
      expect(t.sent, isEmpty);

      t.location.access = LocationAccess.granted; // e.g. fixed in system settings
      await elapse(tester, const Duration(seconds: 61));
      await t.settle();

      expect(t.state.status, TrackingStatus.tracking);
      expect(t.sent, isNotEmpty);
      t.end();
    });

    testWidgets('reports when location services are switched off mid-way', (tester) async {
      final t = await _Tracking.start(tester);

      t.location.access = LocationAccess.serviceDisabled;
      t.location.updates.addError(Exception('Location services disabled'));
      await t.settle();

      expect(t.state.status, TrackingStatus.unavailable);
      expect(t.state.access, LocationAccess.serviceDisabled);
      expect(t.location.updates.hasListener, isFalse);
      t.end();
    });

    testWidgets('stops when the server says the volunteer is no longer available', (tester) async {
      final t = await _Tracking.start(tester);

      // e.g. suspended by an admin: the next heartbeat is refused.
      t.volunteerStatus = 'OFFLINE';
      t.locationResponse = FakeResponse.error(409, 'VOLUNTEER_NOT_AVAILABLE');
      await elapse(tester, const Duration(seconds: 61));
      await t.settle();

      expect(t.state.status, TrackingStatus.off);
      expect(t.location.updates.hasListener, isFalse);
    });
  });

  group('volunteer screens', () {
    Responder backend({Map<String, Object?>? route, String volunteerStatus = 'ACTIVE'}) =>
        (r) async {
          if (r.path.endsWith('/volunteers/me')) {
            return FakeResponse.ok(volunteerJson(status: volunteerStatus));
          }
          if (r.path.endsWith('/volunteers/me/emergencies')) {
            return FakeResponse.ok({'items': <Object>[], 'page': 1, 'limit': 50, 'total': 0});
          }
          if (r.path.endsWith('/emergencies/e1/route')) return FakeResponse.ok(route);
          if (r.path.endsWith('/emergencies/e1')) return FakeResponse.ok(dispatchedJson());
          return FakeResponse.ok(null);
        };

    testWidgets('the dashboard shows live sharing, or how to fix it', (tester) async {
      final location = FakeLocationService(access: LocationAccess.denied);
      final app = await pumpSignedInApp(
        tester,
        role: 'VOLUNTEER',
        location: location,
        respond: backend(),
      );

      final banner = find.byKey(const Key('volunteer.trackingOff'));
      expect(banner, findsOneWidget);
      expect(find.text('Location sharing is off'), findsOneWidget);

      location.access = LocationAccess.granted; // the user allows it
      await tester.tap(find.descendant(of: banner, matching: find.text('Allow')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(location.requestCount, greaterThan(0));
      expect(banner, findsNothing);
      expect(find.textContaining('Sharing live location'), findsOneWidget);
      await unmountApp(tester, app.container);
    });

    Future<({ProviderContainer container, FakeHttpAdapter http})> openDetail(
      WidgetTester tester,
      Map<String, Object?> route,
    ) async {
      final app = await pumpSignedInApp(
        tester,
        role: 'VOLUNTEER',
        respond: backend(route: route),
      );
      unawaited(app.container.read(routerProvider).push(AppRoutes.volunteerEmergency('e1')));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      return (container: app.container, http: app.http);
    }

    testWidgets('the response map draws the road route with its ETA', (tester) async {
      final app = await openDetail(tester, routeJson());

      expect(find.byKey(const Key('volunteer.routeEta')), findsOneWidget);
      expect(find.textContaining('12 min'), findsOneWidget); // 690 s, rounded up
      expect(find.byType(PolylineLayer), findsOneWidget);
      expect(app.http.requests.where((r) => r.path.endsWith('/emergencies/e1/route')), isNotEmpty);
      await unmountApp(tester, app.container);
    });

    testWidgets('a straight-line estimate is labelled and not drawn as a path', (tester) async {
      final app = await openDetail(tester, routeJson(source: 'FALLBACK'));

      expect(find.byKey(const Key('volunteer.routeEta')), findsOneWidget);
      expect(find.textContaining('Estimated from straight-line distance'), findsOneWidget);
      expect(find.byType(PolylineLayer), findsNothing);
      await unmountApp(tester, app.container);
    });
  });
}
