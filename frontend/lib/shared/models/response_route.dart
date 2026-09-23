import '../../core/utils/json.dart';
import 'geo_point.dart';

enum RouteSource {
  /// Road network route from the routing provider.
  routing,

  /// Straight-line estimate used when routing is unavailable (D-010).
  fallback;

  static RouteSource fromApi(Object? value) => value == 'ROUTING' ? routing : fallback;
}

/// Route and ETA from the volunteer's location to an emergency
/// (`GET /volunteers/me/emergencies/:id/route`).
class ResponseRoute {
  const ResponseRoute({
    required this.origin,
    required this.destination,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.source,
    this.geometry = const [],
    this.computedAt,
  });

  factory ResponseRoute.fromJson(Object? value) {
    final json = asJsonMap(value);
    final origin = GeoPoint.tryFromJson(json['origin']);
    final destination = GeoPoint.tryFromJson(json['destination']);
    if (origin == null || destination == null) {
      throw const FormatException('Route without origin or destination');
    }
    return ResponseRoute(
      origin: origin,
      destination: destination,
      distanceMeters: asDouble(json['distanceMeters']) ?? 0,
      durationSeconds: asInt(json['durationSeconds']) ?? 0,
      source: RouteSource.fromApi(json['source']),
      geometry: [for (final item in asJsonList(json['geometry'])) ?GeoPoint.tryFromJson(item)],
      computedAt: asDateTime(json['computedAt']),
    );
  }

  final GeoPoint origin;
  final GeoPoint destination;
  final double distanceMeters;
  final int durationSeconds;
  final RouteSource source;

  /// Polyline points, origin first. Only the two end points for an estimate.
  final List<GeoPoint> geometry;
  final DateTime? computedAt;

  bool get isEstimate => source == RouteSource.fallback;
}
