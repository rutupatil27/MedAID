import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../app/router/app_routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/cards/medical_camp_card.dart';
import '../../../../../core/widgets/chips/status_chip.dart';
import '../../../../../core/widgets/empty_states/empty_state_view.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../application/admin_camp_providers.dart';
import '../../domain/admin_camp.dart';

/// Medical Camps management (doc 27, admin #12).
class AdminCampsScreen extends ConsumerWidget {
  const AdminCampsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final format = AppFormatters.of(context);
    final filter = ref.watch(adminCampFilterProvider);

    return AppScaffold(
      title: l10n.adminCampsTitle,
      showBack: false,
      scrollable: false,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminCampCreate),
        icon: const Icon(Icons.add_location_alt_rounded),
        label: Text(l10n.adminCreateCamp),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (value, label) in <(CampLifecycle?, String)>[
                  (null, l10n.adminFilterAll),
                  (CampLifecycle.activeNow, l10n.campLifecycleActiveNow),
                  (CampLifecycle.upcoming, l10n.campLifecycleUpcoming),
                  (CampLifecycle.expired, l10n.campLifecycleExpired),
                  (CampLifecycle.inactive, l10n.campLifecycleInactive),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: filter == value,
                      onSelected: (_) => ref.read(adminCampFilterProvider.notifier).set(value),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: AsyncValueView<List<AdminCamp>>(
              value: ref.watch(adminCampsProvider),
              onRetry: () => ref.invalidate(adminCampsProvider),
              isEmpty: (items) => items.isEmpty,
              empty: EmptyStateView(
                title: l10n.adminCampsEmpty,
                icon: Icons.medical_services_outlined,
              ),
              data: (camps) => ListView.separated(
                padding: const EdgeInsets.only(bottom: AppSpacing.huge * 2),
                itemCount: camps.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) {
                  final camp = camps[i];
                  return MedicalCampCard(
                    name: camp.name,
                    typeLabel: camp.address,
                    validityLabel: format.dateTimeRange(camp.startDateTime, camp.endDateTime),
                    services: camp.services,
                    badges: [
                      StatusChip(label: camp.lifecycle.label(l10n), tone: camp.lifecycle.tone),
                    ],
                    onTap: () => context.push(AppRoutes.adminCamp(camp.id)),
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
