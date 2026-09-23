import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medaid/app/app.dart';
import 'package:medaid/core/network/api_exception.dart';
import 'package:medaid/core/network/network_providers.dart';
import 'package:medaid/core/storage/preferences_storage.dart';
import 'package:medaid/core/storage/token_storage.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  late InMemoryTokenStorage tokens;

  Future<FakeHttpAdapter> pumpApp(
    WidgetTester tester,
    Future<FakeResponse> Function(RequestOptionsLike r) respond,
  ) async {
    tokens = InMemoryTokenStorage();
    final adapter = FakeHttpAdapter((o) => respond(RequestOptionsLike(o.path, o.data)));
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          preferencesStorageProvider.overrideWithValue(await fakePreferences()),
          tokenStorageProvider.overrideWithValue(tokens),
          dioProvider.overrideWithValue(fakeDio(adapter)),
        ],
        child: const MedAidApp(),
      ),
    );
    await tester.pumpAndSettle();
    return adapter;
  }

  testWidgets('shows validation errors before calling the API', (tester) async {
    final adapter = await pumpApp(tester, (_) async => FakeResponse.ok(null));

    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsNWidgets(2));
    expect(adapter.requests, isEmpty);
  });

  testWidgets('a volunteer login lands on the volunteer area', (tester) async {
    await pumpApp(tester, (r) async => FakeResponse.ok(sessionJson(role: 'VOLUNTEER')));

    await tester.enterText(find.byKey(const Key('login.identifier')).last, 'asha');
    await tester.enterText(find.byKey(const Key('login.password')).last, 'Secure123');
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pumpAndSettle();

    expect(find.text('Hello, Asha Patil'), findsOneWidget);
    expect(tokens.tokens?.refreshToken, 'refresh-token');
  });

  testWidgets('wrong credentials show a localized message', (tester) async {
    await pumpApp(tester, (_) async => FakeResponse.error(401, ApiErrorCodes.authInvalid));

    await tester.enterText(find.byKey(const Key('login.identifier')).last, 'asha');
    await tester.enterText(find.byKey(const Key('login.password')).last, 'wrongpass1');
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email/username or password.'), findsOneWidget);
    expect(tokens.tokens, isNull);
  });
}

class RequestOptionsLike {
  const RequestOptionsLike(this.path, this.data);

  final String path;
  final Object? data;
}
