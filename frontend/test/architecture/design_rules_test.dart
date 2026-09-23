import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Automated checks for the project rules in docs 15, 16, 17 and 25.
void main() {
  final libFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.replaceAll(r'\', '/').contains('/localization/generated/'))
      .toList();

  String rel(File f) => f.path.replaceAll(r'\', '/');

  const themeFile = 'lib/core/theme/app_theme.dart';

  test('there is exactly one theme file', () {
    final themes = libFiles.where((f) => rel(f).endsWith('_theme.dart')).map(rel).toList();
    expect(themes, [themeFile]);
  });

  test('no hardcoded colours outside the global theme', () {
    final pattern = RegExp(r'Color\(0x|Colors\.(?!transparent\b)[a-z]');
    final offenders = [
      for (final f in libFiles)
        if (rel(f) != themeFile && pattern.hasMatch(f.readAsStringSync())) rel(f),
    ];
    expect(offenders, isEmpty, reason: 'Use tokens from app_theme.dart');
  });

  test('no hardcoded user-facing strings in Text widgets', () {
    // Legal attribution is intentionally untranslated.
    const allowed = {'© OpenStreetMap contributors'};
    final pattern = RegExp(r'''Text\(\s*(['"])(.+?)\1''');
    final offenders = <String>[];
    for (final f in libFiles) {
      for (final match in pattern.allMatches(f.readAsStringSync())) {
        final literal = match.group(2)!;
        if (!allowed.contains(literal)) offenders.add('${rel(f)}: $literal');
      }
    }
    expect(offenders, isEmpty, reason: 'Use AppLocalizations keys');
  });

  test('presentation code never calls the network layer directly', () {
    final offenders = [
      for (final f in libFiles)
        if (rel(f).contains('/presentation/') &&
            RegExp(
              r'''import .*(package:dio/|core/network/api_client\.dart)''',
            ).hasMatch(f.readAsStringSync()))
          rel(f),
    ];
    expect(offenders, isEmpty, reason: 'Go through repositories and providers');
  });

  test('the new material_ui package is not mixed with the SDK Material library', () {
    final offenders = [
      for (final f in libFiles)
        if (f.readAsStringSync().contains('package:material_ui/')) rel(f),
    ];
    expect(offenders, isEmpty, reason: 'See DECISIONS D-020');
  });
}
