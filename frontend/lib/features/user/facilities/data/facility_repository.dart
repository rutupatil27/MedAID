import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/utils/json.dart';
import '../../../../shared/models/geo_point.dart';
import '../domain/facility.dart';

class FacilityRepository {
  const FacilityRepository(this._api);

  final ApiClient _api;

  static const _radiusMeters = 15000;

  Future<List<Facility>> nearby(GeoPoint point, {FacilityFilter filter = FacilityFilter.all}) =>
      _api.get(
        '/facilities/nearby',
        query: {
          ...point.toJson(),
          'radiusMeters': _radiusMeters,
          'type': switch (filter) {
            FacilityFilter.all => 'ALL',
            FacilityFilter.hospitals => 'HOSPITAL',
            FacilityFilter.camps => 'CAMP',
          },
        },
        decode: (data) => asJsonList(data).map(Facility.fromJson).toList(),
      );

  Future<Facility> byId(FacilityType type, String id) => _api.get(
    type == FacilityType.camp ? '/medical-camps/$id' : '/hospitals/$id',
    decode: (data) => Facility.fromJson(asJsonMap(data)),
  );
}

final facilityRepositoryProvider = Provider<FacilityRepository>(
  (ref) => FacilityRepository(ref.watch(apiClientProvider)),
);
