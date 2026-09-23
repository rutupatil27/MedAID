import '../../../../core/utils/json.dart';

class SymptomOption {
  const SymptomOption({required this.key, required this.name});

  factory SymptomOption.fromJson(JsonMap json) =>
      SymptomOption(key: asStringOr(json['key'], ''), name: asStringOr(json['name'], ''));

  final String key;
  final String name;
}

class SymptomCategory {
  const SymptomCategory({required this.key, required this.name, required this.symptoms});

  factory SymptomCategory.fromJson(JsonMap json) => SymptomCategory(
    key: asStringOr(json['key'], ''),
    name: asStringOr(json['name'], ''),
    symptoms: asJsonList(json['symptoms']).map(SymptomOption.fromJson).toList(),
  );

  final String key;
  final String name;
  final List<SymptomOption> symptoms;
}

enum AgeGroup {
  youngChild('YOUNG_CHILD'),
  child('CHILD'),
  adult('ADULT'),
  olderAdult('OLDER_ADULT');

  const AgeGroup(this.apiValue);

  final String apiValue;
}

enum SymptomDuration {
  today(0),
  fewDays(1),
  longer(3);

  const SymptomDuration(this.days);

  final int days;
}

enum TriageLevel {
  emergency,
  urgent,
  routine;

  static TriageLevel fromApi(Object? value) => switch (value) {
    'EMERGENCY' => emergency,
    'URGENT' => urgent,
    _ => routine,
  };
}

enum TriageAction {
  sos,
  callEmergency,
  findFacility;

  static TriageAction? fromApi(Object? value) => switch (value) {
    'SOS' => sos,
    'CALL_EMERGENCY' => callEmergency,
    'FIND_FACILITY' => findFacility,
    _ => null,
  };
}

class TriageResult {
  const TriageResult({
    required this.level,
    required this.title,
    required this.message,
    required this.advice,
    required this.firstAid,
    required this.actions,
    required this.warningSigns,
    required this.redFlags,
    required this.selectedSymptoms,
    required this.disclaimer,
  });

  factory TriageResult.fromJson(JsonMap json) => TriageResult(
    level: TriageLevel.fromApi(json['level']),
    title: asStringOr(json['title'], ''),
    message: asStringOr(json['message'], ''),
    advice: asStringList(json['advice']),
    firstAid: asStringList(json['firstAid']),
    actions: asStringList(json['actions']).map(TriageAction.fromApi).nonNulls.toList(),
    warningSigns: asStringList(json['warningSigns']),
    redFlags: asStringList(json['redFlags']),
    selectedSymptoms: asJsonList(json['selectedSymptoms']).map(SymptomOption.fromJson).toList(),
    disclaimer: asStringOr(json['disclaimer'], ''),
  );

  final TriageLevel level;
  final String title;
  final String message;
  final List<String> advice;

  /// Short steps the person can take right now (FR-03).
  final List<String> firstAid;
  final List<TriageAction> actions;
  final List<String> warningSigns;
  final List<String> redFlags;
  final List<SymptomOption> selectedSymptoms;
  final String disclaimer;
}
