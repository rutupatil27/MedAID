import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../app/router/app_routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../../core/widgets/cards/action_card.dart';
import '../../../../../core/widgets/chips/status_chip.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../../core/widgets/misc/profile_avatar.dart';
import '../../../../../shared/models/volunteer.dart';
import '../../../../auth/presentation/logout_action.dart';
import '../../../application/volunteer_controller.dart';

class VolunteerProfileScreen extends ConsumerWidget {
  const VolunteerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    const gap = SizedBox(height: AppSpacing.md);

    return AppScaffold(
      title: l10n.profileTitle,
      showBack: false,
      body: AsyncValueView<Volunteer>(
        value: ref.watch(volunteerProvider),
        onRetry: () => ref.invalidate(volunteerProvider),
        data: (v) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ProfileAvatar(name: v.account.name, size: AppSizes.avatarLg),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.account.name, style: context.textStyles.titleLarge),
                      Text(v.account.email, style: context.textStyles.bodySmall),
                      const SizedBox(height: AppSpacing.sm),
                      StatusChip(
                        label: v.verificationStatus.label(l10n),
                        tone: v.verificationStatus.tone,
                        icon: Icons.verified_user_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            ActionCard(
              title: l10n.profileCompleteTitle,
              subtitle: v.profile.phone,
              icon: Icons.badge_outlined,
              onTap: () => context.push(AppRoutes.volunteerCompleteProfile),
            ),
            gap,
            ActionCard(
              title: l10n.volunteerProfileDocuments,
              icon: Icons.folder_open_rounded,
              tone: AppTone.info,
              onTap: () => context.push(AppRoutes.volunteerDocuments),
            ),
            gap,
            ActionCard(
              title: l10n.verificationTitle,
              icon: Icons.verified_rounded,
              tone: AppTone.success,
              onTap: () => context.push(AppRoutes.volunteerVerification),
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
      ),
    );
  }
}
