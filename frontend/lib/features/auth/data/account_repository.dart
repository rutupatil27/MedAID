import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/utils/json.dart';
import '../../../shared/models/app_user.dart';

/// The signed-in account (`/users/me`), shared by every role.
class AccountRepository {
  const AccountRepository(this._api);

  final ApiClient _api;

  static AppUser _decode(Object? data) => AppUser.fromJson(asJsonMap(data));

  Future<AppUser> fetch() => _api.get('/users/me', decode: _decode);

  Future<AppUser> update({
    String? name,
    String? phone,
    String? preferredLanguage,
    MedicalProfile? medicalProfile,
  }) => _api.patch(
    '/users/me',
    body: {
      'name': ?name,
      'phone': ?phone,
      'preferredLanguage': ?preferredLanguage,
      'medicalProfile': ?medicalProfile?.toJson(),
    },
    decode: _decode,
  );
}

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(apiClientProvider)),
);
