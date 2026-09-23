import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/locale_provider.dart';
import '../data/symptom_repository.dart';
import '../domain/symptom_models.dart';

/// Localized symptom catalogue; reloads when the app language changes.
final symptomCatalogProvider = FutureProvider.autoDispose<List<SymptomCategory>>((ref) {
  ref.watch(localeProvider);
  return ref.watch(symptomRepositoryProvider).fetchCatalog();
});

class SymptomCheckerState {
  const SymptomCheckerState({
    this.selected = const {},
    this.ageGroup = AgeGroup.adult,
    this.pregnant = false,
    this.duration = SymptomDuration.today,
    this.result = const AsyncData(null),
  });

  final Set<String> selected;
  final AgeGroup ageGroup;
  final bool pregnant;
  final SymptomDuration duration;

  /// Null data until a check has been run.
  final AsyncValue<TriageResult?> result;

  bool get canSubmit => selected.isNotEmpty && !result.isLoading;

  SymptomCheckerState copyWith({
    Set<String>? selected,
    AgeGroup? ageGroup,
    bool? pregnant,
    SymptomDuration? duration,
    AsyncValue<TriageResult?>? result,
  }) => SymptomCheckerState(
    selected: selected ?? this.selected,
    ageGroup: ageGroup ?? this.ageGroup,
    pregnant: pregnant ?? this.pregnant,
    duration: duration ?? this.duration,
    result: result ?? this.result,
  );
}

class SymptomCheckerController extends Notifier<SymptomCheckerState> {
  @override
  SymptomCheckerState build() => const SymptomCheckerState();

  void toggle(String key) {
    final next = {...state.selected};
    if (!next.remove(key)) next.add(key);
    state = state.copyWith(selected: next);
  }

  void setAgeGroup(AgeGroup value) => state = state.copyWith(ageGroup: value);

  void setPregnant(bool value) => state = state.copyWith(pregnant: value);

  void setDuration(SymptomDuration value) => state = state.copyWith(duration: value);

  /// Returns true when a result is available.
  Future<bool> submit() async {
    if (!state.canSubmit) return false;
    state = state.copyWith(result: const AsyncLoading());
    final result = await AsyncValue.guard(
      () => ref
          .read(symptomRepositoryProvider)
          .check(
            symptoms: state.selected,
            ageGroup: state.ageGroup,
            pregnant: state.pregnant,
            duration: state.duration,
          ),
    );
    if (!ref.mounted) return false;
    state = state.copyWith(result: result);
    return result.hasValue;
  }

  void reset() => state = const SymptomCheckerState();
}

final symptomCheckerProvider = NotifierProvider<SymptomCheckerController, SymptomCheckerState>(
  SymptomCheckerController.new,
);
