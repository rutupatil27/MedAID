import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/notifications/background_alerts.dart';
import 'core/storage/preferences_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Before runApp: Android can deliver an emergency push before there is an
  // app to hand it to, and the handler must already be registered.
  await registerBackgroundPush();

  runApp(
    ProviderScope(
      // Failed requests surface through ErrorView with an explicit retry
      // instead of silent automatic retries on congested networks.
      retry: (_, _) => null,
      overrides: [preferencesStorageProvider.overrideWithValue(PreferencesStorage(prefs))],
      child: const MedAidApp(),
    ),
  );
}
