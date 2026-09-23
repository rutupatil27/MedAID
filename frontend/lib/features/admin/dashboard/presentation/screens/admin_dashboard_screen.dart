import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../app/router/app_routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/cards/stat_card.dart';
import '../../../../../core/widgets/empty_states/empty_state_view.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/layout/section_header.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../../shared/enums/volunteer_enums.dart';
import '../../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../emergencies/application/admin_emergency_providers.dart';
import '../../../emergencies/data/admin_emergency_repository.dart';
import '../../../emergencies/presentation/widgets/admin_emergency_card.dart';
import '../../../volunteers/application/admin_volunteer_providers.dart';
import '../../../volunteers/data/admin_volunteer_repository.dart';
import '../../application/admin_dashboard_provider.dart';
import '../../domain/admin_dashboard.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    void openEmergencies(AdminEmergencyFilter filter) {
      ref.read(adminEmergencyFilterProvider.notifier).set(filter);
      context.go(AppRoutes.adminEmergencies);
    }

    void openVolunteers(VolunteerFilter filter) {
      ref.read(adminVolunteerFilterProvider.notifier).set(filter);
      context.go(AppRoutes.adminVolunteers);
    }

    return AppScaffold(
      title: l10n.adminDashboardTitle,
      subtitle: l10n.adminDashboardSubtitle,
      showBack: false,
      actions: const [NotificationBell()],
      onRefresh: () => ref.refresh(adminDashboardProvider.future),
      body: AsyncValueView<AdminDashboard>(
        value: ref.watch(adminDashboardProvider),
        onRetry: () => ref.invalidate(adminDashboardProvider),
        data: (d) {
          final stats = [
            (
              l10n.adminStatOpen,
              d.openEmergencies,
              Icons.emergency_rounded,
              AppTone.emergency,
              () => openEmergencies(AdminEmergencyFilter.open),
            ),
            (
              l10n.adminStatUnassigned,
              d.unassigned,
              Icons.person_search_rounded,
              AppTone.danger,
              () => openEmergencies(AdminEmergencyFilter.unassigned),
            ),
            (
              l10n.adminStatAwaiting,
              d.awaitingAcceptance,
              Icons.hourglass_top_rounded,
              AppTone.warning,
              () => openEmergencies(AdminEmergencyFilter.open),
            ),
            (
              l10n.adminStatInProgress,
              d.inProgress,
              Icons.directions_run_rounded,
              AppTone.info,
              () => openEmergencies(AdminEmergencyFilter.open),
            ),
            (
              l10n.adminStatPendingVerification,
              d.pendingVerification,
              Icons.fact_check_outlined,
              AppTone.warning,
              () => openVolunteers(
                const VolunteerFilter(verificationStatus: VerificationStatus.pending),
              ),
            ),
            (
              l10n.adminStatActiveVolunteers,
              d.activeVolunteers,
              Icons.volunteer_activism_rounded,
              AppTone.success,
              () => openVolunteers(const VolunteerFilter(status: VolunteerStatus.active)),
            ),
            (
              l10n.adminStatBusyVolunteers,
              d.busyVolunteers,
              Icons.directions_walk_rounded,
              AppTone.info,
              () => openVolunteers(const VolunteerFilter(status: VolunteerStatus.busy)),
            ),
            (
              l10n.adminStatActiveCamps,
              d.activeCamps,
              Icons.medical_services_rounded,
              AppTone.brand,
              () => context.go(AppRoutes.adminCamps),
            ),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 700 ? 4 : 2;
                  final width = (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final (label, value, icon, tone, onTap) in stats)
                        SizedBox(
                          width: width,
                          child: StatCard(
                            label: label,
                            value: '$value',
                            icon: icon,
                            tone: tone,
                            onTap: onTap,
                          ),
                        ),
                    ],
                  );
                },
              ),
              SectionHeader(
                title: l10n.adminRecentOpen,
                actionLabel: l10n.commonViewAll,
                onAction: () => openEmergencies(AdminEmergencyFilter.open),
              ),
              if (d.recentOpen.isEmpty)
                EmptyStateView(title: l10n.adminNoOpenEmergencies, icon: Icons.check_circle_outline)
              else
                for (final emergency in d.recentOpen) ...[
                  AdminEmergencyCard(
                    emergency: emergency,
                    onTap: () => context.push(AppRoutes.adminEmergency(emergency.id)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
            ],
          );
        },
      ),
    );
  }
}
