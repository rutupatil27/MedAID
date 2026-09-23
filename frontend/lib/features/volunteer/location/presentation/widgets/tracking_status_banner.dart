import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../core/location/location_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../application/location_tracking_controller.dart';

/// Shows whether live location is being shared, and how to fix it when it is
/// not (a volunteer without fresh location stops receiving emergencies).
class TrackingStatusBanner extends ConsumerWidget {
  const TrackingStatusBanner({super.key});

  Future<void> _fix(WidgetRef ref, LocationAccess? access) async {
    final service = ref.read(locationServiceProvider);
    switch (access) {
      case LocationAccess.serviceDisabled:
        await service.openLocationSettings();
      case LocationAccess.deniedForever:
        await service.openAppSettings();
      case LocationAccess.denied || LocationAccess.granted || null:
        await service.requestAccess();
    }
    await ref.read(locationTrackingProvider.notifier).retry();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tracking = ref.watch(locationTrackingProvider);

    switch (tracking.status) {
      case TrackingStatus.off:
        return const SizedBox.shrink();
      case TrackingStatus.tracking:
        final sentAt = tracking.lastSentAt;
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Row(
            children: [
              Icon(
                Icons.my_location_rounded,
                size: AppSizes.iconSm,
                color: context.palette.success,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  sentAt == null
                      ? l10n.trackingStarting
                      : l10n.trackingActive(AppFormatters.of(context).relativeTime(sentAt)),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      case TrackingStatus.unavailable:
        final servicesOff = tracking.access == LocationAccess.serviceDisabled;
        final settings = servicesOff || tracking.access == LocationAccess.deniedForever;
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: AppCard(
            key: const Key('volunteer.trackingOff'),
            color: context.palette.warningContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_off_rounded, color: context.palette.warning),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(l10n.trackingOffTitle, style: context.textStyles.titleSmall),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  servicesOff ? l10n.trackingServicesOffMessage : l10n.trackingPermissionMessage,
                  style: context.textStyles.bodyMedium,
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => _fix(ref, tracking.access),
                    child: Text(settings ? l10n.commonOpenSettings : l10n.commonAllow),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}
