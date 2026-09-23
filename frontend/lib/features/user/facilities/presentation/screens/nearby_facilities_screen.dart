import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../app/router/app_routes.dart';
import '../../../../../core/location/location_providers.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../../core/widgets/map/location_map.dart';
import '../../../../../core/widgets/map/map_marker.dart';
import '../../../../../core/widgets/misc/location_access_prompt.dart';
import '../../application/facilities_providers.dart';
import '../../domain/facility.dart';
import '../widgets/facility_tile.dart';

class NearbyFacilitiesScreen extends ConsumerWidget {
  const NearbyFacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final nearby = ref.watch(nearbyFacilitiesProvider);
    final filter = ref.watch(facilityFilterProvider);
    final showMap = ref.watch(facilityMapModeProvider);

    void retry() => ref.invalidate(currentLocationProvider);
    void open(Facility f) => context.push(AppRoutes.userFacility(f.type.apiValue, f.id));

    return AppScaffold(
      title: l10n.facilitiesTitle,
      subtitle: l10n.facilitiesSubtitle,
      showBack: false,
      scrollable: false,
      actions: [
        IconButton.filledTonal(
          tooltip: showMap ? l10n.facilitiesViewList : l10n.facilitiesViewMap,
          onPressed: ref.read(facilityMapModeProvider.notifier).toggle,
          icon: Icon(showMap ? Icons.view_list_rounded : Icons.map_rounded),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (value, label) in [
                  (FacilityFilter.all, l10n.facilitiesFilterAll),
                  (FacilityFilter.hospitals, l10n.facilitiesFilterHospitals),
                  (FacilityFilter.camps, l10n.facilitiesFilterCamps),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: filter == value,
                      onSelected: (_) => ref.read(facilityFilterProvider.notifier).select(value),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: AsyncValueView<NearbyFacilities>(
              value: nearby,
              onRetry: retry,
              data: (result) => switch (result) {
                NearbyFacilitiesNeedLocation(:final access) => LocationAccessPrompt(
                  access: access,
                  onRetry: retry,
                ),
                // Nothing nearby: say so, but keep the map, which still shows
                // where the person is and lets them look around.
                NearbyFacilitiesLoaded(:final origin, :final facilities)
                    when showMap || facilities.isEmpty =>
                  Column(
                    children: [
                      if (facilities.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: AppCard(
                            color: context.palette.surfaceMuted,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.facilitiesEmptyTitle,
                                  style: context.textStyles.titleSmall,
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  l10n.facilitiesEmptyMessage,
                                  style: context.textStyles.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: LocationMap(
                            center: origin.point.toLatLng(),
                            fitToContent: true,
                            markers: [
                              MapMarkerData(
                                id: 'me',
                                point: origin.point.toLatLng(),
                                kind: MapMarkerKind.currentLocation,
                              ),
                              for (final f in facilities)
                                MapMarkerData(
                                  id: '${f.type.apiValue}:${f.id}',
                                  point: f.location.toLatLng(),
                                  kind: f.isCamp ? MapMarkerKind.camp : MapMarkerKind.hospital,
                                  label: f.name,
                                ),
                            ],
                            onMarkerTap: (marker) {
                              final match = facilities.where(
                                (f) => '${f.type.apiValue}:${f.id}' == marker.id,
                              );
                              if (match.isNotEmpty) open(match.first);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                NearbyFacilitiesLoaded(:final facilities) => RefreshIndicator(
                  onRefresh: () => ref.refresh(nearbyFacilitiesProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    itemCount: facilities.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) =>
                        FacilityTile(facility: facilities[i], onTap: () => open(facilities[i])),
                  ),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
