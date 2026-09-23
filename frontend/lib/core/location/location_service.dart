import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../shared/models/geo_point.dart';

enum LocationAccess { granted, denied, deniedForever, serviceDisabled }

class LocationFix {
  const LocationFix({required this.point, required this.timestamp, this.accuracyMeters});

  final GeoPoint point;
  final double? accuracyMeters;
  final DateTime timestamp;
}

/// Device location behind an interface so features and tests never depend on
/// geolocator directly.
abstract interface class LocationService {
  Future<LocationAccess> checkAccess();

  /// Asks for permission when it has not been permanently denied.
  Future<LocationAccess> requestAccess();

  /// Best effort: a fresh fix, else the last known one, else null. Never throws.
  Future<LocationFix?> currentFix({Duration timeout});

  /// Continuous updates (volunteer tracking, Phase 9).
  Stream<LocationFix> watch({
    required int distanceFilterMeters,
    required Duration interval,
    String? foregroundNotificationTitle,
    String? foregroundNotificationText,
  });

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  static LocationFix _toFix(Position p) => LocationFix(
    point: GeoPoint(latitude: p.latitude, longitude: p.longitude),
    accuracyMeters: p.accuracy,
    timestamp: p.timestamp,
  );

  static LocationAccess _map(LocationPermission permission) => switch (permission) {
    LocationPermission.always || LocationPermission.whileInUse => LocationAccess.granted,
    LocationPermission.deniedForever => LocationAccess.deniedForever,
    LocationPermission.denied || LocationPermission.unableToDetermine => LocationAccess.denied,
  };

  @override
  Future<LocationAccess> checkAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceDisabled;
    return _map(await Geolocator.checkPermission());
  }

  @override
  Future<LocationAccess> requestAccess() async {
    final current = await checkAccess();
    if (current != LocationAccess.denied) return current;
    return _map(await Geolocator.requestPermission());
  }

  @override
  Future<LocationFix?> currentFix({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      if (await checkAccess() != LocationAccess.granted) return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high, timeLimit: timeout),
      );
      return _toFix(position);
    } catch (_) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        return last == null ? null : _toFix(last);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Stream<LocationFix> watch({
    required int distanceFilterMeters,
    required Duration interval,
    String? foregroundNotificationTitle,
    String? foregroundNotificationText,
  }) {
    final background = foregroundNotificationTitle != null;
    final LocationSettings settings = switch (defaultTargetPlatform) {
      // A foreground service with a visible notification keeps updates flowing
      // while the app is in the background.
      TargetPlatform.android => AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
        intervalDuration: interval,
        foregroundNotificationConfig: background
            ? ForegroundNotificationConfig(
                notificationTitle: foregroundNotificationTitle,
                notificationText: foregroundNotificationText ?? '',
                enableWakeLock: true,
              )
            : null,
      ),
      // Requires UIBackgroundModes=location; iOS shows its own indicator.
      TargetPlatform.iOS => AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
        allowBackgroundLocationUpdates: background,
        showBackgroundLocationIndicator: background,
        pauseLocationUpdatesAutomatically: false,
      ),
      _ => LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: distanceFilterMeters),
    };
    return Geolocator.getPositionStream(locationSettings: settings).map(_toFix);
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);
