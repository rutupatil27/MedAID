import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../app/router/app_routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/empty_states/empty_state_view.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../../shared/models/emergency.dart';
import '../../../application/volunteer_emergency_providers.dart';
import '../widgets/volunteer_emergency_card.dart';

/// Assigned Emergencies + Emergency History (doc 27, volunteer #8, #12).
class VolunteerEmergenciesScreen extends ConsumerStatefulWidget {
  const VolunteerEmergenciesScreen({super.key});

  @override
  ConsumerState<VolunteerEmergenciesScreen> createState() => _VolunteerEmergenciesScreenState();
}

class _VolunteerEmergenciesScreenState extends ConsumerState<VolunteerEmergenciesScreen> {
  bool _history = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    Widget list(List<Emergency> items) => ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) => VolunteerEmergencyCard(
        emergency: items[i],
        onTap: () => context.push(AppRoutes.volunteerEmergency(items[i].id)),
      ),
    );

    return AppScaffold(
      title: l10n.volunteerEmergenciesTitle,
      showBack: false,
      scrollable: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(l10n.volunteerActiveTab)),
              ButtonSegment(value: true, label: Text(l10n.volunteerHistoryTab)),
            ],
            selected: {_history},
            onSelectionChanged: (s) => setState(() => _history = s.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: _history
                ? AsyncValueView(
                    value: ref.watch(volunteerHistoryProvider),
                    onRetry: () => ref.invalidate(volunteerHistoryProvider),
                    isEmpty: (page) => page.items.isEmpty,
                    empty: EmptyStateView(
                      title: l10n.emergencyHistoryEmptyTitle,
                      message: l10n.volunteerHistoryEmpty,
                      icon: Icons.history_rounded,
                    ),
                    data: (page) => list(page.items),
                  )
                : AsyncValueView(
                    value: ref.watch(activeAssignmentsProvider),
                    onRetry: () => ref.invalidate(activeAssignmentsProvider),
                    isEmpty: (items) => items.isEmpty,
                    empty: EmptyStateView(
                      title: l10n.volunteerNoAssignmentTitle,
                      message: l10n.volunteerNoAssignmentMessage,
                      icon: Icons.volunteer_activism_rounded,
                    ),
                    data: list,
                  ),
          ),
        ],
      ),
    );
  }
}
