import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../app/router/app_routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/error_messages.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../../core/widgets/dialogs/app_snackbar.dart';
import '../../../../../core/widgets/empty_states/empty_state_view.dart';
import '../../../../../core/widgets/inputs/search_field.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/layout/section_header.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../application/symptom_checker_controller.dart';
import '../../domain/symptom_models.dart';

class SymptomCheckerScreen extends ConsumerStatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  ConsumerState<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends ConsumerState<SymptomCheckerScreen> {
  String _query = '';

  Future<void> _submit() async {
    final ok = await ref.read(symptomCheckerProvider.notifier).submit();
    if (!mounted) return;
    if (ok) {
      await context.push(AppRoutes.userSymptomResult);
    } else {
      final error = ref.read(symptomCheckerProvider).result.error;
      if (error != null) {
        showAppSnackbar(
          context,
          localizedErrorMessage(AppLocalizations.of(context), error),
          tone: AppTone.danger,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(symptomCatalogProvider);
    final checker = ref.watch(symptomCheckerProvider);
    final notifier = ref.read(symptomCheckerProvider.notifier);

    return AppScaffold(
      title: l10n.symptomsTitle,
      subtitle: l10n.symptomsSubtitle,
      scrollable: false,
      bottomAction: PrimaryButton(
        key: const Key('symptoms.submit'),
        label: checker.selected.isEmpty
            ? l10n.symptomsCheckButton
            : '${l10n.symptomsCheckButton} · ${l10n.symptomsSelectedCount(checker.selected.length)}',
        isLoading: checker.result.isLoading,
        onPressed: checker.canSubmit ? _submit : null,
      ),
      body: AsyncValueView<List<SymptomCategory>>(
        value: catalog,
        onRetry: () => ref.invalidate(symptomCatalogProvider),
        data: (categories) {
          final filtered = _filter(categories);
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: [
              _EmergencyShortcut(onTap: () => context.push(AppRoutes.userSos)),
              const SizedBox(height: AppSpacing.lg),
              SearchField(
                hint: l10n.symptomsSearchHint,
                onChanged: (v) => setState(() => _query = v),
              ),
              if (filtered.isEmpty)
                EmptyStateView(title: l10n.symptomsNoMatch, icon: Icons.search_off_rounded),
              for (final category in filtered) ...[
                SectionHeader(title: category.name),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final symptom in category.symptoms)
                      FilterChip(
                        label: Text(symptom.name),
                        selected: checker.selected.contains(symptom.key),
                        onSelected: (_) => notifier.toggle(symptom.key),
                      ),
                  ],
                ),
              ],
              SectionHeader(title: l10n.symptomsAboutYou),
              _AboutPerson(state: checker, notifier: notifier),
            ],
          );
        },
      ),
    );
  }

  List<SymptomCategory> _filter(List<SymptomCategory> categories) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return categories;
    return [
      for (final c in categories)
        if (c.symptoms.any((s) => s.name.toLowerCase().contains(q)))
          SymptomCategory(
            key: c.key,
            name: c.name,
            symptoms: c.symptoms.where((s) => s.name.toLowerCase().contains(q)).toList(),
          ),
    ];
  }
}

class _EmergencyShortcut extends StatelessWidget {
  const _EmergencyShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette.tone(AppTone.emergency);
    return AppCard(
      onTap: onTap,
      color: colors.background,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(Icons.emergency_rounded, color: context.palette.emergency),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              AppLocalizations.of(context).symptomsEmergencyShortcut,
              style: context.textStyles.labelLarge?.copyWith(color: colors.foreground),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.foreground),
        ],
      ),
    );
  }
}

class _AboutPerson extends StatelessWidget {
  const _AboutPerson({required this.state, required this.notifier});

  final SymptomCheckerState state;
  final SymptomCheckerController notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ages = {
      AgeGroup.youngChild: l10n.symptomsAgeYoungChild,
      AgeGroup.child: l10n.symptomsAgeChild,
      AgeGroup.adult: l10n.symptomsAgeAdult,
      AgeGroup.olderAdult: l10n.symptomsAgeOlder,
    };
    final durations = {
      SymptomDuration.today: l10n.symptomsDurationToday,
      SymptomDuration.fewDays: l10n.symptomsDurationFewDays,
      SymptomDuration.longer: l10n.symptomsDurationLonger,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final entry in ages.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: state.ageGroup == entry.key,
                onSelected: (_) => notifier.setAgeGroup(entry.key),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.symptomsPregnant),
          value: state.pregnant,
          onChanged: notifier.setPregnant,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.symptomsDurationLabel, style: context.textStyles.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final entry in durations.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: state.duration == entry.key,
                onSelected: (_) => notifier.setDuration(entry.key),
              ),
          ],
        ),
      ],
    );
  }
}
