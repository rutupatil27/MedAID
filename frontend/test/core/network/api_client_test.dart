import 'package:flutter_test/flutter_test.dart';
import 'package:medaid/core/network/api_client.dart';
import 'package:medaid/core/network/api_exception.dart';

import '../../helpers/fakes.dart';

void main() {
  group('ApiClient', () {
    test('unwraps the success envelope', () async {
      final api = ApiClient(fakeDio(FakeHttpAdapter((_) async => FakeResponse.ok({'value': 42}))));

      final value = await api.get('/thing', decode: (data) => (data! as Map)['value']);

      expect(value, 42);
    });

    test('maps error envelopes to ApiException with field errors', () async {
      final api = ApiClient(
        fakeDio(
          FakeHttpAdapter(
            (_) async => const FakeResponse(409, {
              'success': false,
              'message': 'Duplicate',
              'code': 'CONFLICT',
              'errors': [
                {'field': 'body.email', 'message': 'Already in use'},
              ],
            }),
          ),
        ),
      );

      await expectLater(
        api.post<void>('/auth/register', body: const {}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', ApiErrorCodes.conflict)
              .having((e) => e.statusCode, 'status', 409)
              .having((e) => e.errors.single.field, 'field', 'body.email'),
        ),
      );
    });

    test('maps connection failures to NETWORK_ERROR', () async {
      final api = ApiClient(fakeDio(FakeHttpAdapter((_) async => const FakeResponse.offline())));

      await expectLater(
        api.get('/thing', decode: (d) => d),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', ApiErrorCodes.network)),
      );
    });

    test('falls back to a status-based code when the body is not an envelope', () async {
      final api = ApiClient(fakeDio(FakeHttpAdapter((_) async => const FakeResponse(403, 'nope'))));

      await expectLater(
        api.get('/thing', decode: (d) => d),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', ApiErrorCodes.forbidden)),
      );
    });
  });
}
