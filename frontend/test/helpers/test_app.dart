import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:medaid/app/localization/generated/app_localizations.dart';
import 'package:medaid/app/localization/locale_provider.dart';
import 'package:medaid/core/storage/preferences_storage.dart';
import 'package:medaid/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds a [PreferencesStorage] backed by in-memory SharedPreferences.
Future<PreferencesStorage> fakePreferences([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return PreferencesStorage(await SharedPreferences.getInstance());
}

/// Pumps [child] inside the real theme + localization setup, without routing.
Future<void> pumpThemed(
  WidgetTester tester,
  Widget child, {
  Locale locale = AppLocales.english,
  List<Override> overrides = const [],
}) async {
  final prefs = await fakePreferences();
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [preferencesStorageProvider.overrideWithValue(prefs), ...overrides],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        supportedLocales: AppLocales.supported,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Scaffold(body: child),
      ),
    ),
  );
}
