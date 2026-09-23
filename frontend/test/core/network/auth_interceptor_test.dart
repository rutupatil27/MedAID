import 'package:flutter_test/flutter_test.dart';
import 'package:medaid/core/network/api_client.dart';
import 'package:medaid/core/network/api_exception.dart';
import 'package:medaid/core/network/auth_interceptor.dart';
import 'package:medaid/shared/models/auth_tokens.dart';

import '../../helpers/fakes.dart';

void main() {
  late InMemoryTokenStorage storage;
  late int expiredEvents;

  setUp(() {
    storage = InMemoryTokenStorage(const AuthTokens(accessToken: 'old', refreshToken: 'r1'));
    expiredEvents = 0;
  });

  ApiClient buildClient(FakeHttpAdapter api, FakeHttpAdapter refresh) {
    final dio = fakeDio(api);
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        storage: storage,
        onSessionExpired: () => expiredEvents++,
        refreshDio: fakeDio(refresh),
      ),
    );
    return ApiClient(dio);
  }

  test('attaches the bearer token and skips it for login', () async {
    final api = FakeHttpAdapter((_) async => FakeResponse.ok(null));
    final client = buildClient(api, FakeHttpAdapter((_) async => FakeResponse.ok(null)));

    await client.get('/users/me', decode: (d) => d);
    await client.post<void>('/auth/login', body: const {});

    expect(api.requests[0].headers['Authorization'], 'Bearer old');
    expect(api.requests[1].headers.containsKey('Authorization'), isFalse);
  });

  test('refreshes once for concurrent expired requests and retries them', () async {
    final api = FakeHttpAdapter((options) async {
      final auth = options.headers['Authorization'];
      return auth == 'Bearer new'
          ? FakeResponse.ok({'path': options.path})
          : FakeResponse.error(401, ApiErrorCodes.authUnauthorized);
    });
    final refresh = FakeHttpAdapter(
      (_) async => FakeResponse.ok({'accessToken': 'new', 'refreshToken': 'r2'}),
    );
    final client = buildClient(api, refresh);

    final results = await Future.wait([
      client.get('/a', decode: (d) => d),
      client.get('/b', decode: (d) => d),
    ]);

    expect(results, hasLength(2));
    expect(refresh.requests, hasLength(1));
    expect(storage.tokens?.refreshToken, 'r2');
    expect(expiredEvents, 0);
  });

  test('ends the session when the refresh token is rejected', () async {
    final api = FakeHttpAdapter(
      (_) async => FakeResponse.error(401, ApiErrorCodes.authUnauthorized),
    );
    final refresh = FakeHttpAdapter(
      (_) async => FakeResponse.error(401, ApiErrorCodes.authUnauthorized),
    );
    final client = buildClient(api, refresh);

    await expectLater(
      client.get('/users/me', decode: (d) => d),
      throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'unauthorized', isTrue)),
    );
    expect(storage.tokens, isNull);
    expect(expiredEvents, 1);
  });

  test('keeps the session when refresh fails because the device is offline', () async {
    final api = FakeHttpAdapter(
      (_) async => FakeResponse.error(401, ApiErrorCodes.authUnauthorized),
    );
    final client = buildClient(api, FakeHttpAdapter((_) async => const FakeResponse.offline()));

    await expectLater(client.get('/users/me', decode: (d) => d), throwsA(isA<ApiException>()));
    expect(storage.tokens, isNotNull);
    expect(expiredEvents, 0);
  });

  test('does not try to refresh on authorization failures', () async {
    final api = FakeHttpAdapter((_) async => FakeResponse.error(403, ApiErrorCodes.forbidden));
    final refresh = FakeHttpAdapter((_) async => FakeResponse.ok(null));
    final client = buildClient(api, refresh);

    await expectLater(
      client.get('/admin/dashboard', decode: (d) => d),
      throwsA(isA<ApiException>()),
    );
    expect(refresh.requests, isEmpty);
  });
}
