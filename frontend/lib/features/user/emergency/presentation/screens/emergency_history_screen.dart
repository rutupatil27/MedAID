import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../app/router/app_routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/cards/emergency_card.dart';
import '../../../../../core/widgets/empty_states/empty_state_view.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../../shared/models/emergency.dart';
import '../../../../../shared/models/geo_point.dart';
import '../../application/user_emergency_providers.dart';

class EmergencyHistoryScreen extends ConsumerWidget {
  const EmergencyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final format = AppFormatters.of(context);
    final history = ref.watch(emergencyHistoryProvider);

    return AppScaffold(
      title: l10n.homeHistoryTitle,
      subtitle: l10n.homeHistorySubtitle,
      showBack: false,
      scrollable: false,
      body: AsyncValueView<Paged<Emergency>>(
        value: history,
        onRetry: () => ref.invalidate(emergencyHistoryProvider),
        isEmpty: (page) => page.items.isEmpty,
        empty: EmptyStateView(
          title: l10n.emergencyHistoryEmptyTitle,
          message: l10n.emergencyHistoryEmptyMessage,
          icon: Icons.history_rounded,
        ),
        data: (page) => RefreshIndicator(
          onRefresh: () => ref.refresh(emergencyHistoryProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            itemCount: page.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final emergency = page.items[index];
              return EmergencyCard(
                title: emergency.alertNumber,
                statusLabel: emergency.status.label(l10n),
                statusTone: emergency.status.tone,
                timeLabel: format.relativeTime(emergency.createdAt),
                highlight: emergency.isOpen,
                onTap: () => context.push(AppRoutes.userEmergency(emergency.id)),
              );
            },
          ),
        ),
      ),
    );
  }
}
