import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/utils/json.dart';
import '../../../../shared/models/geo_point.dart';
import '../domain/admin_camp.dart';

class AdminCampRepository {
  const AdminCampRepository(this._api);

  final ApiClient _api;

  static const _base = '/admin/medical-camps';

  static AdminCamp _decode(Object? data) => AdminCamp.fromJson(asJsonMap(data));

  /// [lifecycle] null lists every camp.
  Future<Paged<AdminCamp>> list({CampLifecycle? lifecycle, int limit = 100}) => _api.get(
    _base,
    query: {'limit': limit, 'status': lifecycle?.apiValue ?? 'ALL'},
    decode: (data) => Paged.fromJson(data, AdminCamp.fromJson),
  );

  Future<AdminCamp> get(String id) => _api.get('$_base/$id', decode: _decode);

  Future<AdminCamp> create(CampDraft draft) =>
      _api.post(_base, body: draft.toJson(), decode: _decode);

  Future<AdminCamp> update(String id, CampDraft draft) =>
      _api.patch('$_base/$id', body: draft.toJson(), decode: _decode);

  Future<void> delete(String id) => _api.delete<void>('$_base/$id');
}

final adminCampRepositoryProvider = Provider<AdminCampRepository>(
  (ref) => AdminCampRepository(ref.watch(apiClientProvider)),
);
