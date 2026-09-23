import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../app/router/app_routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../../core/widgets/chips/status_chip.dart';
import '../../../../../core/widgets/empty_states/empty_state_view.dart';
import '../../../../../core/widgets/inputs/search_field.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../../core/widgets/misc/profile_avatar.dart';
import '../../../../../shared/enums/volunteer_enums.dart';
import '../../../../../shared/models/volunteer.dart';
import '../../application/admin_volunteer_providers.dart';
import '../../data/admin_volunteer_repository.dart';

/// Volunteers + Verification Queue (doc 27, admin #5, #8).
class AdminVolunteersScreen extends ConsumerWidget {
  const AdminVolunteersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(adminVolunteerFilterProvider);
    final setFilter = ref.read(adminVolunteerFilterProvider.notifier).set;

    final presets = [
      (const VolunteerFilter(), l10n.adminFilterAll),
      (
        const VolunteerFilter(verificationStatus: VerificationStatus.pending),
        l10n.adminFilterPendingVerification,
      ),
      (const VolunteerFilter(status: VolunteerStatus.active), l10n.volunteerStatusActive),
      (const VolunteerFilter(status: VolunteerStatus.busy), l10n.volunteerStatusBusy),
      (const VolunteerFilter(status: VolunteerStatus.offline), l10n.volunteerStatusOffline),
    ];

    return AppScaffold(
      title: l10n.adminVolunteersTitle,
      showBack: false,
      scrollable: false,
      actions: [
        IconButton.filledTonal(
          tooltip: l10n.adminTrackingTitle,
          onPressed: () => context.push(AppRoutes.adminTracking),
          icon: const Icon(Icons.map_rounded),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminVolunteerCreate),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(l10n.adminCreateVolunteer),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchField(
            hint: l10n.adminSearchVolunteers,
            onChanged: (value) => setFilter(filter.copyWith(search: value)),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (preset, label) in presets)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(label),
                      selected:
                          preset.verificationStatus == filter.verificationStatus &&
                          preset.status == filter.status,
                      onSelected: (_) => setFilter(
                        VolunteerFilter(
                          verificationStatus: preset.verificationStatus,
                          status: preset.status,
                          search: filter.search,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: AsyncValueView<List<Volunteer>>(
              value: ref.watch(adminVolunteersProvider),
              onRetry: () => ref.invalidate(adminVolunteersProvider),
              isEmpty: (items) => items.isEmpty,
              empty: EmptyStateView(
                title: l10n.adminVolunteersEmpty,
                icon: Icons.group_off_rounded,
              ),
              data: (items) => ListView.separated(
                padding: const EdgeInsets.only(bottom: AppSpacing.huge * 2),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) => _VolunteerTile(volunteer: items[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VolunteerTile extends StatelessWidget {
  const _VolunteerTile({required this.volunteer});

  final Volunteer volunteer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      onTap: () => context.push(AppRoutes.adminVolunteer(volunteer.id)),
      child: Row(
        children: [
          ProfileAvatar(name: volunteer.account.name),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(volunteer.account.name, style: context.textStyles.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusChip(
                      label: volunteer.verificationStatus.label(l10n),
                      tone: volunteer.verificationStatus.tone,
                    ),
                    StatusChip(
                      label: volunteer.status.label(l10n),
                      tone: volunteer.status.tone,
                      showDot: true,
                    ),
                    if (volunteer.account.isSuspended)
                      StatusChip(label: l10n.adminSuspended, tone: AppTone.danger),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.palette.textMuted),
        ],
      ),
    );
  }
}
