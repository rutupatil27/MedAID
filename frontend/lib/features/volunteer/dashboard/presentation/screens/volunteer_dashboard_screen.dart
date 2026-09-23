import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../app/router/app_routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/error_messages.dart';
import '../../../../../core/widgets/cards/action_card.dart';
import '../../../../../core/widgets/cards/volunteer_status_card.dart';
import '../../../../../core/widgets/chips/status_chip.dart';
import '../../../../../core/widgets/dialogs/app_snackbar.dart';
import '../../../../../core/widgets/empty_states/empty_state_view.dart';
import '../../../../../core/widgets/layout/section_header.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../../core/widgets/misc/profile_avatar.dart';
import '../../../../../shared/enums/volunteer_enums.dart';
import '../../../../../shared/models/volunteer.dart';
import '../../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../application/volunteer_controller.dart';
import '../../../application/volunteer_emergency_providers.dart';
import '../../../emergencies/presentation/widgets/volunteer_emergency_card.dart';
import '../../../location/presentation/widgets/tracking_status_banner.dart';

class VolunteerDashboardScreen extends ConsumerWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volunteer = ref.watch(volunteerProvider);

    return Scaffold(
      body: SafeArea(
        child: AsyncValueView<Volunteer>(
          value: volunteer,
          onRetry: () => ref.invalidate(volunteerProvider),
          data: (v) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(activeAssignmentsProvider);
              await ref.read(volunteerProvider.notifier).refresh();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.lg,
                AppSpacing.screen,
                AppSpacing.xxl,
              ),
              children: [
                _Greeting(volunteer: v),
                const SizedBox(height: AppSpacing.xl),
                if (v.isApproved) ...[
                  _AvailabilityCard(volunteer: v),
                  const TrackingStatusBanner(),
                  const _CurrentAssignment(),
                ] else
                  _OnboardingSteps(volunteer: v),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.volunteer});

  final Volunteer volunteer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeGreeting(volunteer.account.name),
                style: context.textStyles.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                l10n.volunteerDashboardSubtitle,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const NotificationBell(),
        ProfileAvatar(name: volunteer.account.name),
      ],
    );
  }
}

class _AvailabilityCard extends ConsumerStatefulWidget {
  const _AvailabilityCard({required this.volunteer});

  final Volunteer volunteer;

  @override
  ConsumerState<_AvailabilityCard> createState() => _AvailabilityCardState();
}

class _AvailabilityCardState extends ConsumerState<_AvailabilityCard> {
  bool _updating = false;

  Future<void> _toggle(bool available) async {
    setState(() => _updating = true);
    try {
      await ref.read(volunteerProvider.notifier).setAvailable(available);
      ref.invalidate(activeAssignmentsProvider);
    } catch (error) {
      if (mounted) {
        showAppSnackbar(
          context,
          localizedErrorMessage(AppLocalizations.of(context), error),
          tone: AppTone.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = widget.volunteer.status;

    return VolunteerStatusCard(
      title: l10n.volunteerAvailabilityTitle,
      statusLabel: status.label(l10n),
      statusTone: status.tone,
      message: switch (status) {
        VolunteerStatus.active => l10n.volunteerAvailabilityActiveMessage,
        VolunteerStatus.offline => l10n.volunteerAvailabilityOfflineMessage,
        VolunteerStatus.busy => l10n.volunteerAvailabilityBusyMessage,
      },
      switchValue: status != VolunteerStatus.offline,
      switchSemanticLabel: l10n.volunteerAvailabilitySwitch,
      onSwitchChanged: status == VolunteerStatus.busy ? null : _toggle,
      isUpdating: _updating,
    );
  }
}

class _CurrentAssignment extends ConsumerWidget {
  const _CurrentAssignment();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final active = ref.watch(activeAssignmentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.volunteerCurrentAssignment),
        AsyncValueView(
          value: active,
          onRetry: () => ref.invalidate(activeAssignmentsProvider),
          isEmpty: (items) => items.isEmpty,
          empty: EmptyStateView(
            title: l10n.volunteerNoAssignmentTitle,
            message: l10n.volunteerNoAssignmentMessage,
            icon: Icons.volunteer_activism_rounded,
          ),
          data: (items) => Column(
            children: [
              for (final emergency in items)
                VolunteerEmergencyCard(
                  emergency: emergency,
                  onTap: () => context.push(AppRoutes.volunteerEmergency(emergency.id)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingSteps extends StatelessWidget {
  const _OnboardingSteps({required this.volunteer});

  final Volunteer volunteer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget done(bool isDone) => Icon(
      isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
      color: isDone ? context.palette.success : context.palette.textMuted,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.volunteerOnboardingTitle, style: context.textStyles.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.volunteerOnboardingSubtitle, style: context.textStyles.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        ActionCard(
          title: l10n.volunteerStepProfile,
          icon: Icons.badge_outlined,
          trailing: done(volunteer.profileCompleted),
          onTap: () => context.push(AppRoutes.volunteerCompleteProfile),
        ),
        const SizedBox(height: AppSpacing.md),
        ActionCard(
          title: l10n.volunteerStepDocuments,
          icon: Icons.upload_file_rounded,
          tone: AppTone.info,
          trailing: done(volunteer.hasAllDocuments),
          onTap: () => context.push(AppRoutes.volunteerDocuments),
        ),
        const SizedBox(height: AppSpacing.md),
        ActionCard(
          title: l10n.volunteerStepVerification,
          icon: Icons.verified_user_outlined,
          tone: AppTone.warning,
          trailing: StatusChip(
            label: volunteer.verificationStatus.label(l10n),
            tone: volunteer.verificationStatus.tone,
          ),
          onTap: () => context.push(AppRoutes.volunteerVerification),
        ),
      ],
    );
  }
}
