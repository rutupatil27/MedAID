import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive local preferences. Tokens never go here (see TokenStorage).
class PreferencesStorage {
  const PreferencesStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _localeKey = 'app.localeCode';

  String? get localeCode => _prefs.getString(_localeKey);

  Future<void> setLocaleCode(String code) => _prefs.setString(_localeKey, code);
}

/// Overridden in `main.dart` once SharedPreferences has loaded.
final preferencesStorageProvider = Provider<PreferencesStorage>(
  (ref) => throw UnimplementedError('preferencesStorageProvider must be overridden'),
);
