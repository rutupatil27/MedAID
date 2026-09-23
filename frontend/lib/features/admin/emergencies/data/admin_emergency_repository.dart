import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/utils/json.dart';
import '../../../../shared/models/emergency.dart';
import '../../../../shared/models/geo_point.dart';

enum AdminEmergencyFilter { open, unassigned, resolved, all }

class AdminEmergencyRepository {
  const AdminEmergencyRepository(this._api);

  final ApiClient _api;

  static const _base = '/admin/emergencies';

  static Emergency _decode(Object? data) => Emergency.fromJson(asJsonMap(data));

  Future<Paged<Emergency>> list(
    AdminEmergencyFilter filter, {
    String search = '',
    int limit = 50,
  }) => _api.get(
    _base,
    query: {
      'limit': limit,
      ...switch (filter) {
        AdminEmergencyFilter.open => {'open': true},
        AdminEmergencyFilter.unassigned => {'status': 'UNASSIGNED'},
        AdminEmergencyFilter.resolved => {'status': 'RESOLVED'},
        AdminEmergencyFilter.all => const <String, Object>{},
      },
      if (search.isNotEmpty) 'search': search,
    },
    decode: (data) => Paged.fromJson(data, Emergency.fromJson),
  );

  Future<Emergency> get(String id) => _api.get('$_base/$id', decode: _decode);

  /// Re-runs the engine, or assigns to [volunteerId] if it passes eligibility.
  Future<Emergency> reassign(String id, {String? volunteerId}) =>
      _api.post('$_base/$id/reassign', body: {'volunteerId': ?volunteerId}, decode: _decode);

  Future<Emergency> resolve(String id, String note) =>
      _api.post('$_base/$id/resolve', body: {'note': note}, decode: _decode);

  Future<Emergency> cancel(String id, String note) =>
      _api.post('$_base/$id/cancel', body: {'note': note}, decode: _decode);
}

final adminEmergencyRepositoryProvider = Provider<AdminEmergencyRepository>(
  (ref) => AdminEmergencyRepository(ref.watch(apiClientProvider)),
);
