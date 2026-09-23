import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/error_messages.dart';
import '../../../../../core/utils/external_actions.dart';
import '../../../../../core/utils/formatters.dart';
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
import '../../../../../core/widgets/misc/bullet_list.dart';
import '../../../../../core/widgets/misc/countdown_text.dart';
import '../../../../../core/widgets/misc/status_timeline.dart';
import '../../../../../shared/enums/emergency_status.dart';
import '../../../../../shared/enums/volunteer_enums.dart';
import '../../../../../shared/models/app_user.dart';
import '../../../../../shared/models/emergency.dart';
import '../../../../../shared/models/emergency_timeline.dart';
import '../../../application/location_tracking_controller.dart';
import '../../../application/volunteer_controller.dart';
import '../../../application/volunteer_emergency_providers.dart';

/// Emergency Details + response actions (doc 27, volunteer #9-11).
class VolunteerEmergencyDetailScreen extends ConsumerWidget {
  const VolunteerEmergencyDetailScreen({super.key, required this.emergencyId});

  final String emergencyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(volunteerEmergencyProvider(emergencyId));

    return AppScaffold(
      title: l10n.volunteerEmergencyTitle,
      subtitle: detail.value?.alertNumber,
      scrollable: false,
      body: AsyncValueView<Emergency>(
        value: detail,
        onRetry: () => ref.invalidate(volunteerEmergencyProvider(emergencyId)),
        data: (emergency) => _Detail(emergency: emergency),
      ),
    );
  }
}

class _Detail extends ConsumerStatefulWidget {
  const _Detail({required this.emergency});

  final Emergency emergency;

  @override
  ConsumerState<_Detail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_Detail> {
  bool _busy = false;

  VolunteerEmergencyController get _controller =>
      ref.read(volunteerEmergencyProvider(widget.emergency.id).notifier);

  Future<void> _run(Future<void> Function() action, {String? successMessage}) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && successMessage != null) {
        showAppSnackbar(context, successMessage, tone: AppTone.success);
      }
    } catch (error) {
      if (!mounted) return;
      showAppSnackbar(context, localizedErrorMessage(l10n, error), tone: AppTone.danger);
      ref.invalidate(volunteerEmergencyProvider(widget.emergency.id));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmationDialog(
      context,
      title: l10n.volunteerDeclineConfirmTitle,
      message: l10n.volunteerDeclineConfirmMessage,
      confirmLabel: l10n.volunteerDecline,
      destructive: true,
    );
    if (confirmed) await _run(_controller.decline);
  }

  Future<void> _resolve() async {
    final l10n = AppLocalizations.of(context);
    final note = await showNoteSheet(
      context,
      title: l10n.volunteerResolveTitle,
      label: l10n.volunteerResolveNoteLabel,
      hint: l10n.volunteerResolveNoteHint,
      submitLabel: l10n.volunteerResolve,
    );
    if (note == null || !mounted) return;
    await _run(() => _controller.resolve(note), successMessage: l10n.volunteerResolved);
  }

  List<Widget> _actions(AppLocalizations l10n, Emergency e) {
    final assignment = e.assignment?.status;
    const gap = SizedBox(height: AppSpacing.md);

    if (assignment == AssignmentStatus.pending && e.isOpen) {
      return [
        PrimaryButton(
          key: const Key('volunteer.accept'),
          label: l10n.volunteerAccept,
          icon: Icons.check_circle_rounded,
          isLoading: _busy,
          onPressed: () => _run(_controller.accept, successMessage: l10n.volunteerAccepted),
        ),
        gap,
        SecondaryButton(label: l10n.volunteerDecline, onPressed: _busy ? null : _decline),
      ];
    }
    if (assignment == AssignmentStatus.accepted && e.status == EmergencyStatus.accepted) {
      return [
        PrimaryButton(
          label: l10n.volunteerStartAssistance,
          icon: Icons.where_to_vote_rounded,
          isLoading: _busy,
          onPressed: () => _run(_controller.start),
        ),
        gap,
        SecondaryButton(label: l10n.volunteerResolve, onPressed: _busy ? null : _resolve),
      ];
    }
    if (assignment == AssignmentStatus.accepted && e.status == EmergencyStatus.inProgress) {
      return [
        PrimaryButton(
          key: const Key('volunteer.resolve'),
          label: l10n.volunteerResolve,
          icon: Icons.task_alt_rounded,
          isLoading: _busy,
          onPressed: _resolve,
        ),
      ];
    }
    final message = switch (assignment) {
      AssignmentStatus.expired || AssignmentStatus.declined => l10n.volunteerExpiredMessage,
      _ => l10n.volunteerClosedMessage,
    };
    return [
      AppCard(
        color: context.palette.surfaceMuted,
        child: Text(message, style: context.textStyles.bodyMedium),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = AppFormatters.of(context);
    final e = widget.emergency;
    final assignment = e.assignment;
    final reporter = e.reporter;
    final external = ref.read(externalActionsProvider);
    final responding = assignment?.status == AssignmentStatus.accepted && e.isOpen;
    // Route/ETA only while this volunteer holds the assignment (P-20).
    final routeActive = e.isOpen && e.location != null && (assignment?.status.isActive ?? false);
    final route = routeActive ? ref.watch(volunteerRouteProvider(e.id)) : null;
    final routeData = route?.value;
    final myLocation =
        ref.watch(locationTrackingProvider.select((s) => s.lastFix?.point)) ??
        routeData?.origin ??
        ref.watch(volunteerProvider).value?.location?.point;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(volunteerEmergencyProvider(e.id).future),
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(label: e.status.label(l10n), tone: e.status.tone),
              if (assignment != null)
                StatusChip(label: assignment.status.label(l10n), tone: assignment.status.tone),
              if (routeData != null)
                StatusChip(
                  key: const Key('volunteer.routeEta'),
                  label: l10n.volunteerRouteEta(
                    AppFormatters.etaMinutes(routeData.durationSeconds),
                    format.distance(routeData.distanceMeters),
                  ),
                  icon: Icons.directions_walk_rounded,
                )
              else if (assignment?.routeDistanceMeters != null)
                StatusChip(
                  label: format.distance(assignment!.routeDistanceMeters),
                  icon: Icons.near_me_rounded,
                ),
            ],
          ),
          if (assignment?.status == AssignmentStatus.pending) ...[
            const SizedBox(height: AppSpacing.md),
            CountdownText(
              until: assignment!.expiresAt,
              builder: l10n.volunteerRespondWithin,
              style: context.textStyles.titleMedium?.copyWith(color: context.palette.emergency),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          ..._actions(l10n, e),
          SectionHeader(title: l10n.volunteerLocationTitle),
          if (e.location != null) ...[
            SizedBox(
              height: AppSizes.mapPreviewHeight,
              child: LocationMap(
                center: e.location!.toLatLng(),
                fitToContent: myLocation != null,
                // A straight-line estimate is not a path, so only road routes are drawn.
                route: routeData == null || routeData.isEstimate
                    ? const []
                    : [for (final point in routeData.geometry) point.toLatLng()],
                markers: [
                  MapMarkerData(
                    id: 'emergency',
                    point: e.location!.toLatLng(),
                    kind: MapMarkerKind.emergency,
                  ),
                  if (myLocation != null)
                    MapMarkerData(
                      id: 'me',
                      point: myLocation.toLatLng(),
                      kind: MapMarkerKind.volunteer,
                    ),
                ],
              ),
            ),
            if (routeData?.isEstimate ?? false)
              _MapHint(l10n.volunteerRouteEstimated)
            else if (route?.hasError ?? false)
              _MapHint(l10n.volunteerRouteUnavailable),
            if (responding) ...[
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: l10n.volunteerDirections,
                icon: Icons.directions_rounded,
                onPressed: () => external.directionsTo(e.location!),
              ),
            ],
          ] else
            AppCard(color: context.palette.warningContainer, child: Text(l10n.volunteerNoLocation)),
          if (reporter != null) ...[
            SectionHeader(title: l10n.volunteerReporterTitle),
            AppCard(
              child: Row(
                children: [
                  Expanded(child: Text(reporter.name, style: context.textStyles.titleMedium)),
                  if (reporter.phone != null)
                    TextButton.icon(
                      onPressed: () => external.call(reporter.phone!),
                      icon: const Icon(Icons.call_rounded),
                      label: Text(l10n.volunteerCallReporter),
                    ),
                ],
              ),
            ),
            if (responding || assignment?.status == AssignmentStatus.pending) ...[
              SectionHeader(title: l10n.volunteerMedicalInfoTitle),
              _MedicalInfo(profile: reporter.medicalProfile),
            ],
          ],
          if (e.resolutionNote != null) ...[
            SectionHeader(title: l10n.volunteerResolutionTitle),
            Text(e.resolutionNote!, style: context.textStyles.bodyMedium),
          ],
          SectionHeader(title: l10n.emergencyTimelineTitle),
          StatusTimeline(items: emergencyTimelineItems(e.timeline, l10n, format)),
        ],
      ),
    );
  }
}

class _MapHint extends StatelessWidget {
  const _MapHint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Text(
      message,
      style: context.textStyles.bodySmall?.copyWith(color: context.palette.textSecondary),
    ),
  );
}

class _MedicalInfo extends StatelessWidget {
  const _MedicalInfo({required this.profile});

  final MedicalProfile? profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = profile;
    if (p == null) {
      return Text(l10n.volunteerNoMedicalInfo, style: context.textStyles.bodySmall);
    }
    const line = AppFormatters.labelled;
    return AppCard(
      child: BulletList(
        icon: Icons.medical_information_outlined,
        tone: AppTone.emergency,
        items: [
          line(l10n.medicalBloodGroup, p.bloodGroup),
          line(l10n.medicalAllergies, p.allergies),
          line(l10n.medicalConditions, p.medicalConditions),
          line(l10n.medicalEmergencyContactName, p.emergencyContactName),
          line(l10n.medicalEmergencyContactPhone, p.emergencyContactPhone),
        ],
      ),
    );
  }
}
