import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/utils/json.dart';
import '../../../../shared/enums/user_role.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/models/geo_point.dart';

class AdminUserRepository {
  const AdminUserRepository(this._api);

  final ApiClient _api;

  Future<Paged<AppUser>> list({UserRole? role, String search = '', int limit = 100}) => _api.get(
    '/admin/users',
    query: {'limit': limit, 'role': ?role?.apiValue, if (search.isNotEmpty) 'search': search},
    decode: (data) => Paged.fromJson(data, AppUser.fromJson),
  );

  Future<AppUser> setSuspended(String id, {required bool suspended}) => _api.patch(
    '/admin/users/$id/status',
    body: {'accountStatus': suspended ? 'SUSPENDED' : 'ACTIVE'},
    decode: (data) => AppUser.fromJson(asJsonMap(data)),
  );
}

final adminUserRepositoryProvider = Provider<AdminUserRepository>(
  (ref) => AdminUserRepository(ref.watch(apiClientProvider)),
);
