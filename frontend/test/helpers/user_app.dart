import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:medaid/app/app.dart';
import 'package:medaid/core/location/location_service.dart';
import 'package:medaid/core/network/network_providers.dart';
import 'package:medaid/core/notifications/local_notifier.dart';
import 'package:medaid/core/storage/preferences_storage.dart';
import 'package:medaid/core/storage/token_storage.dart';
import 'package:medaid/features/notifications/application/notification_providers.dart';
import 'package:medaid/shared/models/auth_tokens.dart';

import 'fake_location.dart';
import 'fake_notifier.dart';
import 'fakes.dart';
import 'test_app.dart';

typedef Responder = Future<FakeResponse> Function(RequestOptionsView request);

class RequestOptionsView {
  const RequestOptionsView(this.method, this.path, this.data, this.query, this.headers);

  final String method;
  final String path;
  final Object? data;
  final Map<String, dynamic> query;
  final Map<String, dynamic> headers;
}

/// Boots the full app as a signed-in account of [role] with fake network,
/// storage and location. Unhandled requests get an empty success response.
Future<
  ({
    ProviderContainer container,
    FakeHttpAdapter http,
    FakeLocationService location,
    FakeLocalNotifier notifier,
  })
>
pumpSignedInApp(
  WidgetTester tester, {
  String role = 'USER',
  Responder? respond,
  FakeLocationService? location,
  FakeLocalNotifier? notifier,
  List<Override> overrides = const [],
  bool mustChangePassword = false,
}) async {
  final fakeLocation = location ?? FakeLocationService();
  final fakeNotifier = notifier ?? FakeLocalNotifier();
  final http = FakeHttpAdapter((options) async {
    final view = RequestOptionsView(
      options.method,
      options.path,
      options.data,
      options.queryParameters,
      options.headers,
    );
    if (options.path.endsWith('/users/me') && options.method == 'GET') {
      return FakeResponse.ok(userJson(role: role, mustChangePassword: mustChangePassword));
    }
    return await respond?.call(view) ?? FakeResponse.ok(null);
  });

  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      preferencesStorageProvider.overrideWithValue(await fakePreferences()),
      tokenStorageProvider.overrideWithValue(
        InMemoryTokenStorage(const AuthTokens(accessToken: 'a', refreshToken: 'r')),
      ),
      dioProvider.overrideWithValue(fakeDio(http)),
      locationServiceProvider.overrideWithValue(fakeLocation),
      localNotifierProvider.overrideWithValue(fakeNotifier),
      // The unread badge polls in the app; tests opt in by overriding this again.
      notificationPollIntervalProvider.overrideWithValue(null),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);

  // Tall enough that the SOS card and quick actions fit without scrolling.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.4;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MedAidApp()),
  );
  await tester.pumpAndSettle();
  return (container: container, http: http, location: fakeLocation, notifier: fakeNotifier);
}

/// Unmounts the app and disposes its providers so polling timers stop before
/// the test framework checks for pending timers. Disposing twice is safe.
Future<void> unmountApp(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox.shrink());
  container.dispose();
  await tester.pump();
}
