import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Localization review (P-19): User and shared screens must be translated into
/// Hindi and Marathi for V1. Volunteer and Admin strings may still be English
/// and are listed for translators in `l10n_untranslated.json`.
const englishOnlyPrefixes = [
  'volunteer',
  'admin',
  'document',
  'verification',
  'assignment',
  'tracking',
  'nav',
  'camp',
  'role',
];

/// Volunteer onboarding, despite the shared-sounding name.
const englishOnlyKeys = {'profileCompleteTitle', 'profileCompleteSubtitle'};

Map<String, Object?> arb(String language) =>
    jsonDecode(File('lib/app/localization/app_$language.arb').readAsStringSync())
        as Map<String, Object?>;

Iterable<String> placeholdersOf(String value) =>
    RegExp(r'\{(\w+)\}').allMatches(value).map((m) => m.group(1)!);

bool mustBeTranslated(String key) =>
    !englishOnlyKeys.contains(key) && !englishOnlyPrefixes.any((prefix) => key.startsWith(prefix));

void main() {
  final en = arb('en');
  final keys = en.keys.where((k) => !k.startsWith('@')).toList();

  test('the template has metadata only for keys that exist', () {
    final metadata = en.keys.where((k) => k.startsWith('@') && k != '@@locale');
    for (final key in metadata) {
      expect(keys, contains(key.substring(1)), reason: '$key has no string');
    }
    expect(keys, isNotEmpty);
  });

  for (final language in ['hi', 'mr']) {
    group(language, () {
      final translations = arb(language);

      test('every User and shared string is translated', () {
        final missing = keys
            .where(mustBeTranslated)
            .where((key) => (translations[key] as String?)?.trim().isEmpty ?? true)
            .toList();

        expect(missing, isEmpty, reason: 'Untranslated User-facing keys: $missing');
      });

      test('placeholders match the English text', () {
        for (final key in keys) {
          final source = en[key];
          final target = translations[key];
          if (source is! String || target is! String) continue;
          expect(
            placeholdersOf(target).toSet(),
            placeholdersOf(source).toSet(),
            reason: 'Placeholders differ for "$key"',
          );
        }
      });

      test('has no strings the template dropped', () {
        final stale = translations.keys
            .where((k) => !k.startsWith('@'))
            .where((k) => !en.containsKey(k))
            .toList();

        expect(stale, isEmpty, reason: 'Keys no longer in app_en.arb: $stale');
      });
    });
  }
}
