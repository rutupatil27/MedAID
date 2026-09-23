import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medaid/app/localization/locale_provider.dart';
import 'package:medaid/core/network/api_exception.dart';
import 'package:medaid/core/network/network_providers.dart';
import 'package:medaid/core/storage/preferences_storage.dart';
import 'package:medaid/core/storage/token_storage.dart';
import 'package:medaid/features/auth/application/auth_controller.dart';
import 'package:medaid/features/auth/domain/auth_state.dart';
import 'package:medaid/shared/enums/user_role.dart';
import 'package:medaid/shared/models/auth_tokens.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryTokenStorage tokens;
  late FakeHttpAdapter adapter;
  late Future<FakeResponse> Function(String path) respond;

  Future<ProviderContainer> makeContainer() async {
    adapter = FakeHttpAdapter((options) => respond(options.path));
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        preferencesStorageProvider.overrideWithValue(await fakePreferences()),
        tokenStorageProvider.overrideWithValue(tokens),
        dioProvider.overrideWithValue(fakeDio(adapter)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => tokens = InMemoryTokenStorage());

  test('starts signed out when no tokens are stored', () async {
    respond = (_) async => FakeResponse.ok(null);
    final container = await makeContainer();

    expect(await container.read(authProvider.future), isA<Unauthenticated>());
    expect(adapter.requests, isEmpty);
  });

  test('restores a stored session', () async {
    tokens.tokens = const AuthTokens(accessToken: 'a', refreshToken: 'r');
    respond = (_) async => FakeResponse.ok(userJson(role: 'VOLUNTEER'));
    final container = await makeContainer();

    final state = await container.read(authProvider.future);

    expect(state, isA<Authenticated>().having((s) => s.user.role, 'role', UserRole.volunteer));
  });

  test('clears an invalid stored session', () async {
    tokens.tokens = const AuthTokens(accessToken: 'a', refreshToken: 'r');
    respond = (_) async => FakeResponse.error(401, ApiErrorCodes.authUnauthorized);
    final container = await makeContainer();

    expect(await container.read(authProvider.future), isA<Unauthenticated>());
    expect(tokens.tokens, isNull);
  });

  test('surfaces network errors at startup without discarding tokens', () async {
    tokens.tokens = const AuthTokens(accessToken: 'a', refreshToken: 'r');
    respond = (_) async => const FakeResponse.offline();
    final container = await makeContainer();

    await expectLater(container.read(authProvider.future), throwsA(isA<ApiException>()));
    expect(tokens.tokens, isNotNull);
  });

  test('login stores tokens and applies the account language', () async {
    respond = (_) async => FakeResponse.ok(sessionJson(preferredLanguage: 'hi'));
    final container = await makeContainer();
    await container.read(authProvider.future);

    await container.read(authProvider.notifier).login(identifier: 'asha', password: 'Secure123');

    expect(container.read(authProvider).value, isA<Authenticated>());
    expect(tokens.tokens?.accessToken, 'access-token');
    expect(container.read(localeProvider), AppLocales.hindi);
  });

  test('failed login leaves the user signed out', () async {
    respond = (_) async => FakeResponse.error(401, ApiErrorCodes.authInvalid);
    final container = await makeContainer();
    await container.read(authProvider.future);

    await expectLater(
      container.read(authProvider.notifier).login(identifier: 'asha', password: 'wrong'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', ApiErrorCodes.authInvalid)),
    );
    expect(container.read(authProvider).value, isA<Unauthenticated>());
    expect(tokens.tokens, isNull);
  });

  test('logout always clears the local session, even offline', () async {
    tokens.tokens = const AuthTokens(accessToken: 'a', refreshToken: 'r');
    respond = (path) async =>
        path.endsWith('/users/me') ? FakeResponse.ok(userJson()) : const FakeResponse.offline();
    final container = await makeContainer();
    await container.read(authProvider.future);

    await container.read(authProvider.notifier).logout();

    expect(container.read(authProvider).value, isA<Unauthenticated>());
    expect(tokens.tokens, isNull);
  });

  test('a session-expired event signs the user out', () async {
    tokens.tokens = const AuthTokens(accessToken: 'a', refreshToken: 'r');
    respond = (_) async => FakeResponse.ok(userJson());
    final container = await makeContainer();
    await container.read(authProvider.future);

    container.read(sessionExpiredEventsProvider).add(null);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(authProvider).value, isA<Unauthenticated>());
  });
}
