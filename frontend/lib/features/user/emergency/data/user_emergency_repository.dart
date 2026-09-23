import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/location_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/utils/json.dart';
import '../../../../shared/models/emergency.dart';
import '../../../../shared/models/geo_point.dart';

class UserEmergencyRepository {
  const UserEmergencyRepository(this._api);

  final ApiClient _api;

  static Emergency _decode(Object? data) => Emergency.fromJson(asJsonMap(data));

  /// Creates (or returns the already open) emergency. The idempotency key
  /// makes retries after network failures safe (P-08).
  Future<Emergency> create({
    required String idempotencyKey,
    LocationFix? location,
    String? message,
  }) => _api.post(
    '/emergencies',
    headers: {'Idempotency-Key': idempotencyKey},
    body: {
      if (location != null) ...location.point.toJson(),
      if (location?.accuracyMeters != null) 'accuracy': location!.accuracyMeters,
      if (message != null && message.isNotEmpty) 'message': message,
    },
    decode: _decode,
  );

  Future<Paged<Emergency>> listMine({bool? open, int limit = 50}) => _api.get(
    '/emergencies/my',
    query: {'limit': limit, 'open': ?open},
    decode: (data) => Paged.fromJson(data, Emergency.fromJson),
  );

  Future<Emergency> byId(String id) => _api.get('/emergencies/$id', decode: _decode);

  Future<Emergency> cancel(String id, {String? reason}) =>
      _api.post('/emergencies/$id/cancel', body: {'reason': ?reason}, decode: _decode);
}

final userEmergencyRepositoryProvider = Provider<UserEmergencyRepository>(
  (ref) => UserEmergencyRepository(ref.watch(apiClientProvider)),
);
