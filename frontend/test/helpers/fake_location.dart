import 'dart:async';

import 'package:medaid/core/location/location_service.dart';
import 'package:medaid/shared/models/geo_point.dart';

class FakeLocationService implements LocationService {
  FakeLocationService({this.access = LocationAccess.granted, LocationFix? fix})
    : fix = fix ?? nashikFix();

  static LocationFix nashikFix() => LocationFix(
    point: const GeoPoint(latitude: 20.0086, longitude: 73.7925),
    accuracyMeters: 12,
    timestamp: DateTime(2026, 9, 17, 10),
  );

  LocationAccess access;
  LocationFix? fix;
  int requestCount = 0;
  final StreamController<LocationFix> updates = StreamController.broadcast();

  @override
  Future<LocationAccess> checkAccess() async => access;

  @override
  Future<LocationAccess> requestAccess() async {
    requestCount++;
    return access;
  }

  @override
  Future<LocationFix?> currentFix({Duration timeout = Duration.zero}) async =>
      access == LocationAccess.granted ? fix : null;

  @override
  Stream<LocationFix> watch({
    required int distanceFilterMeters,
    required Duration interval,
    String? foregroundNotificationTitle,
    String? foregroundNotificationText,
  }) => updates.stream;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}
