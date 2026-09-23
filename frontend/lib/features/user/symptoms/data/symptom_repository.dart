import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/utils/json.dart';
import '../domain/symptom_models.dart';

class SymptomRepository {
  const SymptomRepository(this._api);

  final ApiClient _api;

  /// Categories are localized by the backend from the Accept-Language header.
  Future<List<SymptomCategory>> fetchCatalog() => _api.get(
    '/symptoms',
    decode: (data) =>
        asJsonList(asJsonMap(data)['categories']).map(SymptomCategory.fromJson).toList(),
  );

  Future<TriageResult> check({
    required Set<String> symptoms,
    required AgeGroup ageGroup,
    required bool pregnant,
    required SymptomDuration duration,
  }) => _api.post(
    '/symptoms/check',
    body: {
      'symptoms': symptoms.toList(),
      'ageGroup': ageGroup.apiValue,
      'pregnant': pregnant,
      'durationDays': duration.days,
    },
    decode: (data) => TriageResult.fromJson(asJsonMap(data)),
  );
}

final symptomRepositoryProvider = Provider<SymptomRepository>(
  (ref) => SymptomRepository(ref.watch(apiClientProvider)),
);
