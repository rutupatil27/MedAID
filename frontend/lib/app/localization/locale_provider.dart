import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/preferences_storage.dart';

abstract final class AppLocales {
  static const Locale english = Locale('en');
  static const Locale hindi = Locale('hi');
  static const Locale marathi = Locale('mr');

  static const List<Locale> supported = [english, hindi, marathi];

  static Locale? tryParse(String? code) {
    for (final locale in supported) {
      if (locale.languageCode == code) return locale;
    }
    return null;
  }
}

/// App language. A saved choice wins, then the device language, then English.
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final saved = AppLocales.tryParse(ref.read(preferencesStorageProvider).localeCode);
    if (saved != null) return saved;
    final device = PlatformDispatcher.instance.locale.languageCode;
    return AppLocales.tryParse(device) ?? AppLocales.english;
  }

  Future<void> setLocale(Locale locale) async {
    final supported = AppLocales.tryParse(locale.languageCode);
    if (supported == null || supported == state) return;
    state = supported;
    await ref.read(preferencesStorageProvider).setLocaleCode(supported.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);
