import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/empty_states/empty_state_view.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../../core/widgets/misc/profile_avatar.dart';
import '../../../volunteers/application/admin_volunteer_providers.dart';

/// Picks an ACTIVE, verified volunteer for manual assignment. The backend
/// re-checks every eligibility rule when assigning (OQ-25).
Future<String?> showVolunteerPickerSheet(BuildContext context) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  builder: (_) => const _VolunteerPicker(),
);

class _VolunteerPicker extends ConsumerWidget {
  const _VolunteerPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppSpacing.screenPadding,
            child: Text(l10n.adminPickVolunteer, style: context.textStyles.titleLarge),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: AsyncValueView(
              value: ref.watch(assignableVolunteersProvider),
              onRetry: () => ref.invalidate(assignableVolunteersProvider),
              isEmpty: (items) => items.isEmpty,
              empty: EmptyStateView(title: l10n.adminNoEligibleVolunteers),
              data: (items) => ListView(
                children: [
                  for (final v in items)
                    ListTile(
                      leading: ProfileAvatar(name: v.account.name, size: AppSizes.avatarSm),
                      title: Text(v.account.name),
                      subtitle: Text(v.profile.city ?? v.account.email),
                      onTap: () => Navigator.of(context).pop(v.id),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
