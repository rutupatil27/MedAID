import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/error_messages.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../../core/widgets/chips/status_chip.dart';
import '../../../../../core/widgets/dialogs/app_snackbar.dart';
import '../../../../../core/widgets/dialogs/confirmation_dialog.dart';
import '../../../../../core/widgets/empty_states/empty_state_view.dart';
import '../../../../../core/widgets/inputs/search_field.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../../core/widgets/misc/profile_avatar.dart';
import '../../../../../shared/enums/user_role.dart';
import '../../../../../shared/models/app_user.dart';
import '../../application/admin_user_providers.dart';

/// Users list with suspend/reactivate (doc 27, admin #14; OQ-11).
class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  static String roleLabel(AppLocalizations l10n, UserRole role) => switch (role) {
    UserRole.user => l10n.roleUser,
    UserRole.volunteer => l10n.roleVolunteer,
    UserRole.admin => l10n.roleAdmin,
  };

  Future<void> _toggle(BuildContext context, WidgetRef ref, AppUser user) async {
    final l10n = AppLocalizations.of(context);
    final suspend = user.accountStatus != AccountStatus.suspended;
    if (suspend) {
      final confirmed = await showConfirmationDialog(
        context,
        title: l10n.adminSuspendConfirmTitle,
        message: l10n.adminSuspendConfirmMessage,
        confirmLabel: l10n.adminSuspend,
        destructive: true,
      );
      if (!confirmed) return;
    }
    try {
      await ref.read(adminUsersProvider.notifier).setSuspended(user.id, suspended: suspend);
      if (context.mounted) {
        showAppSnackbar(context, l10n.adminAccountUpdated, tone: AppTone.success);
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
    final role = ref.watch(adminUserRoleFilterProvider);

    return AppScaffold(
      title: l10n.adminUsersTitle,
      scrollable: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchField(
            hint: l10n.adminSearchUsers,
            onChanged: ref.read(adminUserSearchProvider.notifier).set,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final value in [null, ...UserRole.values])
                ChoiceChip(
                  label: Text(value == null ? l10n.adminFilterAll : roleLabel(l10n, value)),
                  selected: role == value,
                  onSelected: (_) => ref.read(adminUserRoleFilterProvider.notifier).set(value),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: AsyncValueView<List<AppUser>>(
              value: ref.watch(adminUsersProvider),
              onRetry: () => ref.invalidate(adminUsersProvider),
              isEmpty: (items) => items.isEmpty,
              empty: EmptyStateView(title: l10n.adminUsersEmpty, icon: Icons.person_off_outlined),
              data: (users) => ListView.separated(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                itemCount: users.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final user = users[i];
                  final suspended = user.accountStatus == AccountStatus.suspended;
                  return AppCard(
                    child: Row(
                      children: [
                        ProfileAvatar(name: user.name, size: AppSizes.avatarSm),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: context.textStyles.titleSmall),
                              Text(user.email, style: context.textStyles.bodySmall),
                              const SizedBox(height: AppSpacing.xs),
                              Wrap(
                                spacing: AppSpacing.xs,
                                children: [
                                  StatusChip(label: roleLabel(l10n, user.role)),
                                  if (suspended)
                                    StatusChip(label: l10n.adminSuspended, tone: AppTone.danger),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (user.role != UserRole.admin)
                          TextButton(
                            onPressed: () => _toggle(context, ref, user),
                            child: Text(suspended ? l10n.adminReactivate : l10n.adminSuspend),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
