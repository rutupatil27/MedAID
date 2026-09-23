/// Small helpers for decoding API JSON under `strict-casts`.
typedef JsonMap = Map<String, dynamic>;

JsonMap asJsonMap(Object? value) => value is Map<String, dynamic> ? value : <String, dynamic>{};

List<JsonMap> asJsonList(Object? value) =>
    value is List ? value.whereType<Map<String, dynamic>>().toList() : const [];

String? asString(Object? value) => value?.toString();

String asStringOr(Object? value, String fallback) => value?.toString() ?? fallback;

int? asInt(Object? value) => switch (value) {
  final int v => v,
  final num v => v.toInt(),
  final String v => int.tryParse(v),
  _ => null,
};

double? asDouble(Object? value) => switch (value) {
  final num v => v.toDouble(),
  final String v => double.tryParse(v),
  _ => null,
};

bool asBool(Object? value, {bool fallback = false}) => value is bool ? value : fallback;

DateTime? asDateTime(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;

List<String> asStringList(Object? value) =>
    value is List ? value.map((e) => e.toString()).toList() : const [];
