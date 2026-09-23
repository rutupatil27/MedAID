import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../app/router/app_routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/error_messages.dart';
import '../../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../../core/widgets/cards/action_card.dart';
import '../../../../../core/widgets/dialogs/app_snackbar.dart';
import '../../../../../core/widgets/dialogs/note_sheet.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/layout/section_header.dart';
import '../../../../auth/presentation/logout_action.dart';
import '../../../volunteers/data/admin_volunteer_repository.dart';

/// Users, reports, tracking and Settings (doc 27, admin #14-16).
class AdminMoreScreen extends ConsumerWidget {
  const AdminMoreScreen({super.key});

  /// Doc 19 "important admin notice": free text to every verified volunteer.
  Future<void> _sendNotice(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final message = await showNoteSheet(
      context,
      title: l10n.adminNoticeTitle,
      label: l10n.adminNoticeLabel,
      hint: l10n.adminNoticeHint,
      submitLabel: l10n.adminNoticeSend,
      maxLength: 300,
    );
    if (message == null || !context.mounted) return;
    try {
      final count = await ref.read(adminVolunteerRepositoryProvider).sendNotice(message);
      if (context.mounted) {
        showAppSnackbar(context, l10n.adminNoticeSent(count), tone: AppTone.success);
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnackbar(context, localizedErrorMessage(l10n, error), tone: AppTone.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    const gap = SizedBox(height: AppSpacing.md);

    return AppScaffold(
      title: l10n.adminMoreTitle,
      showBack: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ActionCard(
            title: l10n.adminUsersTitle,
            icon: Icons.people_alt_rounded,
            onTap: () => context.push(AppRoutes.adminUsers),
          ),
          gap,
          ActionCard(
            title: l10n.adminReportsTitle,
            subtitle: l10n.adminReportsSubtitle,
            icon: Icons.insights_rounded,
            tone: AppTone.info,
            onTap: () => context.push(AppRoutes.adminReports),
          ),
          gap,
          ActionCard(
            title: l10n.adminTrackingTitle,
            icon: Icons.map_rounded,
            tone: AppTone.success,
            onTap: () => context.push(AppRoutes.adminTracking),
          ),
          gap,
          ActionCard(
            key: const Key('admin.sendNotice'),
            title: l10n.adminNoticeTitle,
            subtitle: l10n.adminNoticeSubtitle,
            icon: Icons.campaign_rounded,
            tone: AppTone.warning,
            onTap: () => _sendNotice(context, ref),
          ),
          SectionHeader(title: l10n.adminSettingsTitle),
          ActionCard(
            title: l10n.profileEditTitle,
            icon: Icons.badge_outlined,
            tone: AppTone.neutral,
            onTap: () => context.push(AppRoutes.adminProfileEdit),
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
