import 'dart:async';

import 'package:dio/dio.dart';

import '../../shared/models/auth_tokens.dart';
import '../storage/token_storage.dart';
import '../utils/json.dart';
import 'api_exception.dart';

/// Attaches the access token and transparently refreshes it once when the
/// server reports an expired session. Concurrent 401s share one refresh.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required this._storage,
    required this._onSessionExpired,
    Dio? refreshDio,
  }) : _dio = dio,
       _refreshDio = refreshDio ?? Dio(dio.options.copyWith());

  final Dio _dio;
  final Dio _refreshDio;
  final TokenStorage _storage;
  final void Function() _onSessionExpired;

  Future<AuthTokens?>? _refreshing;

  static const _retriedKey = 'medaid.authRetried';
  static const _publicPaths = ['/auth/login', '/auth/register', '/auth/refresh'];

  static bool _isPublic(String path) => _publicPaths.any(path.endsWith);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_isPublic(options.path)) {
      final tokens = await _storage.read();
      if (tokens != null) options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final body = asJsonMap(err.response?.data);
    final sessionExpired =
        err.response?.statusCode == 401 && body['code'] == ApiErrorCodes.authUnauthorized;

    if (!sessionExpired || _isPublic(options.path) || options.extra[_retriedKey] == true) {
      return handler.next(err);
    }

    final tokens = await (_refreshing ??= _refresh().whenComplete(() => _refreshing = null));
    if (tokens == null) return handler.next(err);

    try {
      options.extra[_retriedKey] = true;
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      handler.resolve(await _dio.fetch<Object?>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<AuthTokens?> _refresh() async {
    final current = await _storage.read();
    if (current == null) {
      _onSessionExpired();
      return null;
    }
    try {
      final response = await _refreshDio.post<Object?>(
        '/auth/refresh',
        data: {'refreshToken': current.refreshToken},
      );
      final tokens = AuthTokens.fromJson(asJsonMap(asJsonMap(response.data)['data']));
      if (!tokens.isValid) throw StateError('Malformed refresh response');
      await _storage.save(tokens);
      return tokens;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        await _storage.clear();
        _onSessionExpired();
      }
      // Network failures keep the stored session; the original error surfaces.
      return null;
    }
  }
}
