import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/localization/locale_provider.dart';
import '../../theme/app_theme.dart';

/// Pill chips for English / हिन्दी / मराठी. Switching applies instantly.
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key, this.onChanged});

  /// Called after the locale changes (e.g. to sync the user's profile).
  final ValueChanged<Locale>? onChanged;

  static String labelFor(AppLocalizations l10n, Locale locale) => switch (locale.languageCode) {
    'hi' => l10n.languageHindi,
    'mr' => l10n.languageMarathi,
    _ => l10n.languageEnglish,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(localeProvider);

    return Semantics(
      label: l10n.languageTitle,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final locale in AppLocales.supported)
            ChoiceChip(
              label: Text(labelFor(l10n, locale)),
              selected: current.languageCode == locale.languageCode,
              onSelected: (_) async {
                await ref.read(localeProvider.notifier).setLocale(locale);
                onChanged?.call(locale);
              },
            ),
        ],
      ),
    );
  }
}
