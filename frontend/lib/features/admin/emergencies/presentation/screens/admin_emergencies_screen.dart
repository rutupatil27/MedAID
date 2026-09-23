import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../app/router/app_routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/empty_states/empty_state_view.dart';
import '../../../../../core/widgets/inputs/search_field.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../application/admin_emergency_providers.dart';
import '../../data/admin_emergency_repository.dart';
import '../widgets/admin_emergency_card.dart';

/// Emergencies monitor (doc 27, admin #3).
class AdminEmergenciesScreen extends ConsumerWidget {
  const AdminEmergenciesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(adminEmergencyFilterProvider);

    return AppScaffold(
      title: l10n.navEmergencies,
      showBack: false,
      scrollable: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchField(
            hint: l10n.adminSearchAlert,
            onChanged: ref.read(adminEmergencySearchProvider.notifier).set,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final (value, label) in [
                (AdminEmergencyFilter.open, l10n.adminFilterOpen),
                (AdminEmergencyFilter.unassigned, l10n.adminFilterUnassigned),
                (AdminEmergencyFilter.resolved, l10n.adminFilterResolved),
                (AdminEmergencyFilter.all, l10n.adminFilterAll),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: filter == value,
                  onSelected: (_) => ref.read(adminEmergencyFilterProvider.notifier).set(value),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: AsyncValueView(
              value: ref.watch(adminEmergenciesProvider),
              onRetry: () => ref.invalidate(adminEmergenciesProvider),
              isEmpty: (items) => items.isEmpty,
              empty: EmptyStateView(title: l10n.adminEmergenciesEmpty, icon: Icons.inbox_outlined),
              data: (items) => RefreshIndicator(
                onRefresh: () => ref.refresh(adminEmergenciesProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) => AdminEmergencyCard(
                    emergency: items[i],
                    onTap: () => context.push(AppRoutes.adminEmergency(items[i].id)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
