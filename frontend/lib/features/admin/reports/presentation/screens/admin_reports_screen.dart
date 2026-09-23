import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../../core/widgets/cards/stat_card.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/layout/section_header.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../dashboard/application/admin_dashboard_provider.dart';
import '../../data/admin_report_repository.dart';

/// Reports / basic analytics (doc 27, admin #15; OQ-26).
class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    String minutes(int? seconds) =>
        seconds == null ? '—' : l10n.adminMinutes((seconds / 60).ceil());

    return AppScaffold(
      title: l10n.adminReportsTitle,
      subtitle: l10n.adminReportsSubtitle,
      onRefresh: () => ref.refresh(adminReportProvider.future),
      body: AsyncValueView<ReportSummary>(
        value: ref.watch(adminReportProvider),
        onRetry: () => ref.invalidate(adminReportProvider),
        data: (r) {
          final stats = [
            (l10n.adminReportTotal, '${r.total}', Icons.emergency_rounded, AppTone.emergency),
            (l10n.adminReportResolved, '${r.resolved}', Icons.task_alt_rounded, AppTone.success),
            (l10n.adminReportCancelled, '${r.cancelled}', Icons.cancel_outlined, AppTone.neutral),
            (
              l10n.adminReportReassignment,
              '${(r.reassignmentRate * 100).round()}%',
              Icons.replay_rounded,
              AppTone.warning,
            ),
            (
              l10n.adminReportAvgAccept,
              minutes(r.avgTimeToAcceptSeconds),
              Icons.timer_outlined,
              AppTone.info,
            ),
            (
              l10n.adminReportAvgResolve,
              minutes(r.avgTimeToResolveSeconds),
              Icons.timelapse_rounded,
              AppTone.brand,
            ),
          ];
          final maxCount = r.perDay.fold<int>(1, (m, d) => d.count > m ? d.count : m);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - AppSpacing.md) / 2;
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final (label, value, icon, tone) in stats)
                        SizedBox(
                          width: width,
                          child: StatCard(label: label, value: value, icon: icon, tone: tone),
                        ),
                    ],
                  );
                },
              ),
              SectionHeader(title: l10n.adminReportPerDay),
              AppCard(
                child: r.perDay.isEmpty
                    ? Text(l10n.adminReportNoData, style: context.textStyles.bodySmall)
                    : Column(
                        children: [
                          for (final day in r.perDay)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: AppSpacing.huge * 2,
                                    child: Text(day.date, style: context.textStyles.labelSmall),
                                  ),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: AppRadii.pillAll,
                                      child: LinearProgressIndicator(
                                        value: day.count / maxCount,
                                        minHeight: AppSpacing.md,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(day.count.toString(), style: context.textStyles.labelMedium),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
