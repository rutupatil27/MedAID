import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'location_service.dart';

sealed class DeviceLocationState {
  const DeviceLocationState();
}

final class LocationReady extends DeviceLocationState {
  const LocationReady(this.fix);

  final LocationFix fix;
}

final class LocationUnavailable extends DeviceLocationState {
  const LocationUnavailable(this.access);

  /// `granted` here means permission is fine but no fix could be obtained.
  final LocationAccess access;
}

/// One-shot device location for screens such as nearby facilities.
/// Invalidate it to retry after the user grants permission.
final currentLocationProvider = FutureProvider.autoDispose<DeviceLocationState>((ref) async {
  final service = ref.watch(locationServiceProvider);
  final access = await service.requestAccess();
  if (access != LocationAccess.granted) return LocationUnavailable(access);
  final fix = await service.currentFix();
  return fix == null ? const LocationUnavailable(LocationAccess.granted) : LocationReady(fix);
});
