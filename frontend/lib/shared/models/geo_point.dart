import 'package:latlong2/latlong.dart';

import '../../core/utils/json.dart';

class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  static GeoPoint? tryFromJson(Object? value) {
    final json = asJsonMap(value);
    final lat = asDouble(json['latitude']);
    final lng = asDouble(json['longitude']);
    return lat == null || lng == null ? null : GeoPoint(latitude: lat, longitude: lng);
  }

  final double latitude;
  final double longitude;

  LatLng toLatLng() => LatLng(latitude, longitude);

  Map<String, double> toJson() => {'latitude': latitude, 'longitude': longitude};

  @override
  bool operator ==(Object other) =>
      other is GeoPoint && other.latitude == latitude && other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

class Paged<T> {
  const Paged({required this.items, required this.page, required this.limit, required this.total});

  factory Paged.fromJson(Object? data, T Function(JsonMap json) item) {
    final json = asJsonMap(data);
    return Paged(
      items: asJsonList(json['items']).map(item).toList(),
      page: asInt(json['page']) ?? 1,
      limit: asInt(json['limit']) ?? 20,
      total: asInt(json['total']) ?? 0,
    );
  }

  final List<T> items;
  final int page;
  final int limit;
  final int total;

  bool get hasMore => page * limit < total;
}
