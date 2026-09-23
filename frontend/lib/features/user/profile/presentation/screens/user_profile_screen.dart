import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../app/localization/locale_provider.dart';
import '../../../../../app/router/app_routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../../core/widgets/cards/action_card.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/misc/language_selector.dart';
import '../../../../../core/widgets/misc/profile_avatar.dart';
import '../../../../auth/application/auth_controller.dart';
import '../../../../auth/domain/auth_state.dart';
import '../../../../auth/presentation/logout_action.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider).value;
    final user = auth is Authenticated ? auth.user : null;
    final locale = ref.watch(localeProvider);
    const gap = SizedBox(height: AppSpacing.md);

    return AppScaffold(
      title: l10n.profileTitle,
      showBack: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (user != null)
            Row(
              children: [
                ProfileAvatar(name: user.name, size: AppSizes.avatarLg),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: context.textStyles.titleLarge),
                      Text(user.email, style: context.textStyles.bodySmall),
                      Text(user.username, style: context.textStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.xxl),
          ActionCard(
            title: l10n.profilePersonalDetails,
            subtitle: user?.phone,
            icon: Icons.badge_outlined,
            onTap: () => context.push(AppRoutes.userProfileEdit),
          ),
          gap,
          ActionCard(
            title: l10n.profileMedicalInfo,
            subtitle: l10n.profileMedicalInfoSubtitle,
            icon: Icons.medical_information_outlined,
            tone: AppTone.emergency,
            onTap: () => context.push(AppRoutes.userMedicalProfile),
          ),
          gap,
          ActionCard(
            title: l10n.languageTitle,
            subtitle: LanguageSelector.labelFor(l10n, locale),
            icon: Icons.translate_rounded,
            tone: AppTone.info,
            onTap: () => context.push(AppRoutes.userLanguage),
          ),
          gap,
          ActionCard(
            title: l10n.profileChangePassword,
            icon: Icons.lock_reset_rounded,
            tone: AppTone.neutral,
            onTap: () => context.push(AppRoutes.accountPassword),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SecondaryButton(
            label: l10n.authLogout,
            icon: Icons.logout_rounded,
            onPressed: () => confirmAndLogout(context, ref),
          ),
        ],
      ),
    );
  }
}
