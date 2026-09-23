import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/utils/json.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/auth_tokens.dart';
import '../domain/auth_state.dart';

class AuthRepository {
  const AuthRepository(this._api);

  final ApiClient _api;

  static AuthSession _session(Object? data) {
    final json = asJsonMap(data);
    return AuthSession(
      user: AppUser.fromJson(asJsonMap(json['user'])),
      tokens: AuthTokens.fromJson(json),
    );
  }

  Future<AuthSession> login({required String identifier, required String password}) => _api.post(
    '/auth/login',
    body: {'identifier': identifier, 'password': password},
    decode: _session,
  );

  Future<AuthSession> register({
    required String name,
    required String email,
    required String username,
    required String password,
    required String preferredLanguage,
    String? phone,
  }) => _api.post(
    '/auth/register',
    body: {
      'name': name,
      'email': email,
      'username': username,
      'password': password,
      'preferredLanguage': preferredLanguage,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    },
    decode: _session,
  );

  Future<AuthSession> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _api.post(
    '/auth/change-password',
    body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    decode: _session,
  );

  Future<void> logout(String refreshToken) =>
      _api.post<void>('/auth/logout', body: {'refreshToken': refreshToken});

  Future<AppUser> fetchCurrentUser() =>
      _api.get('/users/me', decode: (data) => AppUser.fromJson(asJsonMap(data)));
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);
