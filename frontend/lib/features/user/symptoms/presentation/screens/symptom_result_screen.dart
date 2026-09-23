import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../app/router/app_routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/external_actions.dart';
import '../../../../../core/widgets/buttons/danger_button.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../../core/widgets/chips/status_chip.dart';
import '../../../../../core/widgets/empty_states/empty_state_view.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/layout/section_header.dart';
import '../../../../../core/widgets/misc/bullet_list.dart';
import '../../application/symptom_checker_controller.dart';
import '../../domain/symptom_models.dart';

class SymptomResultScreen extends ConsumerWidget {
  const SymptomResultScreen({super.key});

  static AppTone toneFor(TriageLevel level) => switch (level) {
    TriageLevel.emergency => AppTone.emergency,
    TriageLevel.urgent => AppTone.warning,
    TriageLevel.routine => AppTone.success,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final result = ref.watch(symptomCheckerProvider).result.value;

    if (result == null) {
      return AppScaffold(
        title: l10n.symptomsResultTitle,
        scrollable: false,
        body: EmptyStateView(
          title: l10n.symptomsTitle,
          actionLabel: l10n.symptomsStartOver,
          onAction: () => context.pop(),
        ),
      );
    }

    final levelLabel = switch (result.level) {
      TriageLevel.emergency => l10n.triageEmergency,
      TriageLevel.urgent => l10n.triageUrgent,
      TriageLevel.routine => l10n.triageRoutine,
    };
    final tone = toneFor(result.level);
    final colors = context.palette.tone(tone);
    const gap = SizedBox(height: AppSpacing.md);

    return AppScaffold(
      title: l10n.symptomsResultTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            color: colors.background,
            borderColor: result.level == TriageLevel.emergency ? context.palette.emergency : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusChip(label: levelLabel, tone: tone, icon: Icons.health_and_safety_rounded),
                gap,
                Text(result.title, style: context.textStyles.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(result.message, style: context.textStyles.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final action in result.actions) ...[
            switch (action) {
              TriageAction.sos => DangerButton(
                label: l10n.symptomsUseSos,
                icon: Icons.emergency_rounded,
                onPressed: () => context.push(AppRoutes.userSos),
              ),
              TriageAction.callEmergency => SecondaryButton(
                label: l10n.commonCallEmergency,
                icon: Icons.call_rounded,
                onPressed: () => ref.read(externalActionsProvider).callEmergency(),
              ),
              TriageAction.findFacility => PrimaryButton(
                label: l10n.symptomsFindFacility,
                icon: Icons.local_hospital_rounded,
                onPressed: () => context.go(AppRoutes.userFacilities),
              ),
            },
            gap,
          ],
          if (result.firstAid.isNotEmpty) ...[
            SectionHeader(title: l10n.symptomsFirstAidTitle),
            BulletList(
              items: result.firstAid,
              icon: Icons.medical_services_outlined,
              tone: AppTone.info,
            ),
          ],
          SectionHeader(title: l10n.symptomsWhatToDo),
          BulletList(items: result.advice),
          SectionHeader(title: l10n.symptomsWarningSignsTitle),
          BulletList(
            items: result.warningSigns,
            icon: Icons.warning_amber_rounded,
            tone: AppTone.emergency,
          ),
          SectionHeader(title: l10n.symptomsSelectedTitle),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final s in result.selectedSymptoms) StatusChip(label: s.name)],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: AppSizes.iconMd,
                color: context.palette.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(result.disclaimer, style: context.textStyles.bodySmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: () {
              ref.read(symptomCheckerProvider.notifier).reset();
              context.pop();
            },
            child: Text(l10n.symptomsStartOver),
          ),
        ],
      ),
    );
  }
}
