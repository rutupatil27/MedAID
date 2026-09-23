import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../app/localization/locale_provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/misc/language_selector.dart';
import '../../../../auth/application/account_controller.dart';

/// Language selection (doc 27 #15). Applies instantly and syncs the account.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(localeProvider);

    return AppScaffold(
      title: l10n.languageTitle,
      subtitle: l10n.languageSubtitle,
      body: Column(
        children: [
          for (final locale in AppLocales.supported) ...[
            AppCard(
              onTap: () async {
                try {
                  await ref.read(accountProvider.notifier).changeLanguage(locale);
                } catch (_) {
                  // The language already changed on this device. The account keeps
                  // its previous preference until a later change syncs successfully.
                }
              },
              borderColor: current == locale ? context.colors.primary : null,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      LanguageSelector.labelFor(l10n, locale),
                      style: context.textStyles.titleMedium,
                    ),
                  ),
                  if (current == locale)
                    Icon(Icons.check_circle_rounded, color: context.colors.primary),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
