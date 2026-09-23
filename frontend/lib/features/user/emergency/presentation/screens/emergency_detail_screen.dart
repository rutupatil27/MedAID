import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/error_messages.dart';
import '../../../../../core/utils/external_actions.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/buttons/danger_button.dart';
import '../../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../../core/widgets/chips/status_chip.dart';
import '../../../../../core/widgets/dialogs/app_snackbar.dart';
import '../../../../../core/widgets/dialogs/confirmation_dialog.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/layout/section_header.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../../core/widgets/map/location_map.dart';
import '../../../../../core/widgets/map/map_marker.dart';
import '../../../../../core/widgets/misc/status_timeline.dart';
import '../../../../../shared/enums/emergency_status.dart';
import '../../../../../shared/models/emergency.dart';
import '../../../../../shared/models/emergency_timeline.dart';
import '../../application/user_emergency_providers.dart';

/// Active emergency / emergency detail for the reporting User (doc 27 #11).
class EmergencyDetailScreen extends ConsumerWidget {
  const EmergencyDetailScreen({super.key, required this.emergencyId});

  final String emergencyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(emergencyDetailProvider(emergencyId));

    return AppScaffold(
      title: l10n.emergencyDetailTitle,
      subtitle: detail.value?.alertNumber,
      scrollable: false,
      body: AsyncValueView<Emergency>(
        value: detail,
        onRetry: () => ref.invalidate(emergencyDetailProvider(emergencyId)),
        data: (emergency) => _EmergencyDetail(emergency: emergency),
      ),
    );
  }
}

class _EmergencyDetail extends ConsumerWidget {
  const _EmergencyDetail({required this.emergency});

  final Emergency emergency;

  String _message(AppLocalizations l10n) => switch (emergency.status) {
    EmergencyStatus.accepted =>
      emergency.responder?.name != null
          ? l10n.emergencyMessageAccepted(emergency.responder!.name!)
          : l10n.emergencyMessageAcceptedNoName,
    EmergencyStatus.inProgress => l10n.emergencyMessageInProgress,
    EmergencyStatus.unassigned => l10n.emergencyMessageUnassigned,
    EmergencyStatus.resolved => l10n.emergencyMessageResolved,
    EmergencyStatus.cancelled || EmergencyStatus.expired => l10n.emergencyMessageCancelled,
    EmergencyStatus.created ||
    EmergencyStatus.assigning ||
    EmergencyStatus.assigned => l10n.emergencyMessageSearching,
  };

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmationDialog(
      context,
      title: l10n.emergencyCancelConfirmTitle,
      message: l10n.emergencyCancelConfirmMessage,
      confirmLabel: l10n.emergencyCancelAction,
      cancelLabel: l10n.emergencyKeepAlert,
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(emergencyDetailProvider(emergency.id).notifier).cancel();
      if (context.mounted) showAppSnackbar(context, l10n.emergencyCancelled);
    } catch (error) {
      if (context.mounted) {
        showAppSnackbar(context, localizedErrorMessage(l10n, error), tone: AppTone.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final format = AppFormatters.of(context);
    final status = emergency.status;
    final eta = emergency.responder?.estimatedDurationSeconds;
    final location = emergency.location;
    const gap = SizedBox(height: AppSpacing.md);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(emergencyDetailProvider(emergency.id).future),
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          AppCard(
            borderColor: status.isOpen && !status.isHelpComing ? context.palette.emergency : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: StatusChip(
                        label: status.label(l10n),
                        tone: status.tone,
                        showDot: status.isOpen,
                      ),
                    ),
                    if (status.isOpen) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.emergencyLiveUpdates,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.labelSmall,
                        ),
                      ),
                    ],
                  ],
                ),
                gap,
                Text(_message(l10n), style: context.textStyles.titleMedium),
                if (status.isHelpComing && eta != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.emergencyEta(AppFormatters.etaMinutes(eta)),
                    style: context.textStyles.bodyMedium?.copyWith(color: context.palette.info),
                  ),
                ],
              ],
            ),
          ),
          if (status.isOpen && location == null) ...[
            gap,
            AppCard(
              color: context.palette.warningContainer,
              child: Row(
                children: [
                  Icon(Icons.location_off_rounded, color: context.palette.warning),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(l10n.sosNoLocationWarning)),
                ],
              ),
            ),
          ],
          SectionHeader(
            title: location == null ? l10n.emergencyNoLocation : l10n.emergencyYourLocation,
          ),
          if (location != null)
            SizedBox(
              height: AppSizes.mapPreviewHeight,
              child: LocationMap(
                center: location.toLatLng(),
                markers: [
                  MapMarkerData(
                    id: 'me',
                    point: location.toLatLng(),
                    kind: MapMarkerKind.emergency,
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          SecondaryButton(
            label: l10n.commonCallEmergency,
            icon: Icons.call_rounded,
            onPressed: () => ref.read(externalActionsProvider).callEmergency(),
          ),
          if (status.isOpen) ...[
            gap,
            DangerButton(
              label: l10n.emergencyCancelAction,
              outlined: true,
              onPressed: () => _cancel(context, ref),
            ),
          ],
          SectionHeader(title: l10n.emergencyTimelineTitle),
          StatusTimeline(items: emergencyTimelineItems(emergency.timeline, l10n, format)),
        ],
      ),
    );
  }
}
