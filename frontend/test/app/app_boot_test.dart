import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medaid/app/app.dart';
import 'package:medaid/app/localization/locale_provider.dart';
import 'package:medaid/core/network/network_providers.dart';
import 'package:medaid/core/storage/preferences_storage.dart';
import 'package:medaid/core/storage/token_storage.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';

Future<ProviderContainer> _pumpApp(WidgetTester tester, {String? savedLocale}) async {
  final prefs = await fakePreferences({'app.localeCode': ?savedLocale});
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      preferencesStorageProvider.overrideWithValue(prefs),
      tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
      dioProvider.overrideWithValue(fakeDio(FakeHttpAdapter((_) async => FakeResponse.ok(null)))),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MedAidApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('a signed-out launch lands on the login screen with the global theme', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.textTheme.bodyMedium?.fontFamily, 'Poppins');
  });

  testWidgets('restores a saved Hindi locale', (tester) async {
    await _pumpApp(tester, savedLocale: 'hi');

    expect(find.text('फिर से स्वागत है'), findsOneWidget);
  });

  testWidgets('switches to Marathi from the login screen and persists it', (tester) async {
    final container = await _pumpApp(tester);

    await tester.tap(find.text('मराठी'));
    await tester.pumpAndSettle();

    expect(find.text('पुन्हा स्वागत आहे'), findsOneWidget);
    expect(container.read(localeProvider), AppLocales.marathi);
    expect(container.read(preferencesStorageProvider).localeCode, 'mr');
  });
}
