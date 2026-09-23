import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:medaid/core/storage/token_storage.dart';
import 'package:medaid/shared/models/auth_tokens.dart';

class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage([this.tokens]);

  AuthTokens? tokens;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<void> save(AuthTokens value) async => tokens = value;

  @override
  Future<void> clear() async => tokens = null;
}

class FakeResponse {
  const FakeResponse(this.status, [this.body]) : offline = false;

  const FakeResponse.offline() : status = 0, body = null, offline = true;

  final int status;
  final Object? body;
  final bool offline;

  static FakeResponse ok(Object? data, {int status = 200}) =>
      FakeResponse(status, {'success': true, 'message': 'OK', 'data': data});

  static FakeResponse error(int status, String code) => FakeResponse(status, {
    'success': false,
    'message': 'error',
    'code': code,
    'errors': <Object>[],
  });
}

/// Scriptable HTTP layer for Dio: no real network in tests.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.handler);

  final Future<FakeResponse> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = await handler(options);
    if (response.offline) {
      throw DioException.connectionError(requestOptions: options, reason: 'offline');
    }
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio fakeDio(FakeHttpAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'http://test/api/v1'))..httpClientAdapter = adapter;

Map<String, Object?> userJson({
  String id = 'u1',
  String role = 'USER',
  bool mustChangePassword = false,
  String preferredLanguage = 'en',
}) => {
  'id': id,
  'name': 'Asha Patil',
  'email': 'asha@example.com',
  'username': 'asha',
  'role': role,
  'accountStatus': 'ACTIVE',
  'preferredLanguage': preferredLanguage,
  'mustChangePassword': mustChangePassword,
  'medicalProfile': <String, Object?>{},
};

Map<String, Object?> sessionJson({String role = 'USER', String preferredLanguage = 'en'}) => {
  'user': userJson(role: role, preferredLanguage: preferredLanguage),
  'accessToken': 'access-token',
  'refreshToken': 'refresh-token',
};
