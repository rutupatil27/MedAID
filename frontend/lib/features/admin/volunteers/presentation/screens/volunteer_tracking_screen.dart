import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../app/router/app_routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/chips/status_chip.dart';
import '../../../../../core/widgets/empty_states/empty_state_view.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../../core/widgets/map/location_map.dart';
import '../../../../../core/widgets/map/map_marker.dart';
import '../../../../../shared/enums/volunteer_enums.dart';
import '../../application/admin_volunteer_providers.dart';
import '../../data/admin_volunteer_repository.dart';

/// Volunteer Tracking (doc 27, admin #10). Admin-only view of live positions.
class VolunteerTrackingScreen extends ConsumerWidget {
  const VolunteerTrackingScreen({super.key});

  // Ramkund, Nashik: default view when nobody is sharing a location.
  static const _fallbackCenter = LatLng(20.0086, 73.7925);

  /// Stale positions are greyed out: the engine no longer dispatches to them.
  static AppTone _tone(VolunteerPin pin) =>
      pin.location?.isStale ?? true ? AppTone.neutral : pin.status.tone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return AppScaffold(
      title: l10n.adminTrackingTitle,
      subtitle: l10n.adminTrackingSubtitle,
      scrollable: false,
      body: AsyncValueView(
        value: ref.watch(volunteerPinsProvider),
        onRetry: () => ref.invalidate(volunteerPinsProvider),
        data: (pins) {
          final located = pins.where((p) => p.location != null).toList();
          if (located.isEmpty) {
            return EmptyStateView(title: l10n.adminTrackingEmpty, icon: Icons.location_off_rounded);
          }
          final stale = located.where((p) => p.location!.isStale).length;
          int fresh(VolunteerStatus status) =>
              located.where((p) => !p.location!.isStale && p.status == status).length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  StatusChip(
                    label: l10n.adminTrackingAvailable(fresh(VolunteerStatus.active)),
                    tone: VolunteerStatus.active.tone,
                  ),
                  StatusChip(
                    label: l10n.adminTrackingResponding(fresh(VolunteerStatus.busy)),
                    tone: VolunteerStatus.busy.tone,
                  ),
                  if (stale > 0) StatusChip(label: l10n.adminTrackingStale(stale)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: LocationMap(
                    center: located.first.location?.point.toLatLng() ?? _fallbackCenter,
                    fitToContent: true,
                    markers: [
                      for (final pin in located)
                        MapMarkerData(
                          id: pin.volunteerId,
                          point: pin.location!.point.toLatLng(),
                          kind: MapMarkerKind.volunteer,
                          label: pin.name,
                          tone: _tone(pin),
                        ),
                    ],
                    onMarkerTap: (marker) => context.push(AppRoutes.adminVolunteer(marker.id)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
