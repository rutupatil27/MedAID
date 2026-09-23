import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/location_providers.dart';
import '../../../../core/location/location_service.dart';
import '../data/facility_repository.dart';
import '../domain/facility.dart';

class FacilityFilterController extends Notifier<FacilityFilter> {
  @override
  FacilityFilter build() => FacilityFilter.all;

  void select(FacilityFilter filter) => state = filter;
}

final facilityFilterProvider = NotifierProvider<FacilityFilterController, FacilityFilter>(
  FacilityFilterController.new,
);

class FacilityMapModeController extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

/// True when the nearby facilities screen shows the map instead of the list.
final facilityMapModeProvider = NotifierProvider<FacilityMapModeController, bool>(
  FacilityMapModeController.new,
);

sealed class NearbyFacilities {
  const NearbyFacilities();
}

final class NearbyFacilitiesLoaded extends NearbyFacilities {
  const NearbyFacilitiesLoaded(this.origin, this.facilities);

  final LocationFix origin;
  final List<Facility> facilities;
}

final class NearbyFacilitiesNeedLocation extends NearbyFacilities {
  const NearbyFacilitiesNeedLocation(this.access);

  final LocationAccess access;
}

final nearbyFacilitiesProvider = FutureProvider.autoDispose<NearbyFacilities>((ref) async {
  final location = await ref.watch(currentLocationProvider.future);
  final filter = ref.watch(facilityFilterProvider);
  return switch (location) {
    LocationUnavailable(:final access) => NearbyFacilitiesNeedLocation(access),
    LocationReady(:final fix) => NearbyFacilitiesLoaded(
      fix,
      await ref.watch(facilityRepositoryProvider).nearby(fix.point, filter: filter),
    ),
  };
});

final facilityDetailProvider = FutureProvider.autoDispose
    .family<Facility, ({FacilityType type, String id})>(
      (ref, key) => ref.watch(facilityRepositoryProvider).byId(key.type, key.id),
    );
