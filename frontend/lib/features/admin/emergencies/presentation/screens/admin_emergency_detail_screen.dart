import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/error_messages.dart';
import '../../../../../core/utils/external_actions.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/buttons/danger_button.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../../core/widgets/chips/status_chip.dart';
import '../../../../../core/widgets/dialogs/app_snackbar.dart';
import '../../../../../core/widgets/dialogs/confirmation_dialog.dart';
import '../../../../../core/widgets/dialogs/note_sheet.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/layout/section_header.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../../core/widgets/map/location_map.dart';
import '../../../../../core/widgets/map/map_marker.dart';
import '../../../../../core/widgets/misc/status_timeline.dart';
import '../../../../../shared/models/emergency.dart';
import '../../../../../shared/models/emergency_timeline.dart';
import '../../application/admin_emergency_providers.dart';
import '../widgets/volunteer_picker_sheet.dart';

/// Emergency Details + Assignment History + overrides (doc 27, admin #4, #11).
class AdminEmergencyDetailScreen extends ConsumerWidget {
  const AdminEmergencyDetailScreen({super.key, required this.emergencyId});

  final String emergencyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(adminEmergencyProvider(emergencyId));

    return AppScaffold(
      title: detail.value?.alertNumber ?? l10n.emergencyDetailTitle,
      scrollable: false,
      body: AsyncValueView<Emergency>(
        value: detail,
        onRetry: () => ref.invalidate(adminEmergencyProvider(emergencyId)),
        data: (e) => _Body(emergency: e),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.emergency});

  final Emergency emergency;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  AdminEmergencyController get _controller =>
      ref.read(adminEmergencyProvider(widget.emergency.id).notifier);

  Future<void> _run(Future<void> Function() action, String success) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showAppSnackbar(context, success, tone: AppTone.success);
    } catch (error) {
      if (mounted) {
        showAppSnackbar(context, localizedErrorMessage(l10n, error), tone: AppTone.danger);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reassign({bool chooseVolunteer = false}) async {
    final l10n = AppLocalizations.of(context);
    String? volunteerId;
    if (chooseVolunteer) {
      volunteerId = await showVolunteerPickerSheet(context);
      if (volunteerId == null) return;
    } else {
      final confirmed = await showConfirmationDialog(
        context,
        title: l10n.adminReassignConfirmTitle,
        message: l10n.adminReassignConfirmMessage,
        confirmLabel: l10n.adminReassign,
      );
      if (!confirmed) return;
    }
    await _run(() => _controller.reassign(volunteerId: volunteerId), l10n.adminReassigned);
  }

  Future<void> _close({required bool resolve}) async {
    final l10n = AppLocalizations.of(context);
    final title = resolve ? l10n.adminResolve : l10n.adminCancelEmergency;
    final note = await showNoteSheet(
      context,
      title: title,
      label: l10n.adminCloseNoteLabel,
      submitLabel: title,
    );
    if (note == null) return;
    await _run(
      () => resolve ? _controller.resolve(note) : _controller.cancel(note),
      l10n.adminClosed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = AppFormatters.of(context);
    final e = widget.emergency;
    final reporter = e.reporter;
    final volunteer = e.assignedVolunteer;
    final external = ref.read(externalActionsProvider);
    const gap = SizedBox(height: AppSpacing.md);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            StatusChip(label: e.status.label(l10n), tone: e.status.tone, showDot: e.isOpen),
            StatusChip(label: format.dateTime(e.createdAt), icon: Icons.schedule_rounded),
            if (e.attemptCount > 0) StatusChip(label: l10n.adminAttempts(e.attemptCount)),
          ],
        ),
        if (e.location != null) ...[
          gap,
          SizedBox(
            height: AppSizes.mapPreviewHeight,
            child: LocationMap(
              center: e.location!.toLatLng(),
              markers: [
                MapMarkerData(
                  id: e.id,
                  point: e.location!.toLatLng(),
                  kind: MapMarkerKind.emergency,
                ),
              ],
            ),
          ),
        ],
        SectionHeader(title: l10n.adminReporter),
        AppCard(
          child: Row(
            children: [
              Expanded(child: Text(reporter?.name ?? '—', style: context.textStyles.titleSmall)),
              if (reporter?.phone != null)
                IconButton(
                  tooltip: l10n.facilityCall,
                  onPressed: () => external.call(reporter!.phone!),
                  icon: const Icon(Icons.call_rounded),
                ),
            ],
          ),
        ),
        SectionHeader(title: l10n.adminAssignedVolunteer),
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  volunteer?.name ?? l10n.adminNotAssigned,
                  style: context.textStyles.titleSmall,
                ),
              ),
              if (volunteer?.status != null)
                StatusChip(label: volunteer!.status!.label(l10n), tone: volunteer.status!.tone),
            ],
          ),
        ),
        if (e.isOpen) ...[
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: l10n.adminReassign,
            icon: Icons.person_search_rounded,
            isLoading: _busy,
            onPressed: _reassign,
          ),
          gap,
          SecondaryButton(
            label: l10n.adminReassignTo,
            icon: Icons.person_add_alt_rounded,
            onPressed: _busy ? null : () => _reassign(chooseVolunteer: true),
          ),
          gap,
          SecondaryButton(
            label: l10n.adminResolve,
            icon: Icons.task_alt_rounded,
            onPressed: _busy ? null : () => _close(resolve: true),
          ),
          gap,
          DangerButton(
            label: l10n.adminCancelEmergency,
            outlined: true,
            onPressed: _busy ? null : () => _close(resolve: false),
          ),
        ],
        SectionHeader(title: l10n.adminAssignmentHistory),
        if (e.assignments.isEmpty)
          Text(l10n.adminNoAssignments, style: context.textStyles.bodySmall)
        else
          for (final a in e.assignments) ...[
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(radius: AppSizes.iconMd, child: Text(a.attemptNumber.toString())),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.volunteer?.name ?? '—', style: context.textStyles.titleSmall),
                        Text(format.time(a.dispatchedAt), style: context.textStyles.bodySmall),
                      ],
                    ),
                  ),
                  StatusChip(label: a.status.label(l10n), tone: a.status.tone),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        SectionHeader(title: l10n.emergencyTimelineTitle),
        StatusTimeline(items: emergencyTimelineItems(e.timeline, l10n, format)),
      ],
    );
  }
}
