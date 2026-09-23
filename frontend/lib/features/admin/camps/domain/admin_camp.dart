import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/json.dart';
import '../../../../shared/models/geo_point.dart';

enum CampLifecycle {
  activeNow('ACTIVE_NOW'),
  upcoming('UPCOMING'),
  expired('EXPIRED'),
  inactive('INACTIVE');

  const CampLifecycle(this.apiValue);

  final String apiValue;

  static CampLifecycle fromApi(Object? value) =>
      values.firstWhere((l) => l.apiValue == value, orElse: () => CampLifecycle.inactive);

  String label(AppLocalizations l10n) => switch (this) {
    activeNow => l10n.campLifecycleActiveNow,
    upcoming => l10n.campLifecycleUpcoming,
    expired => l10n.campLifecycleExpired,
    inactive => l10n.campLifecycleInactive,
  };

  AppTone get tone => switch (this) {
    activeNow => AppTone.success,
    upcoming => AppTone.info,
    expired || inactive => AppTone.neutral,
  };
}

class AdminCamp {
  const AdminCamp({
    required this.id,
    required this.name,
    required this.location,
    required this.address,
    required this.startDateTime,
    required this.endDateTime,
    required this.isActive,
    required this.lifecycle,
    this.description,
    this.services = const [],
    this.contactName,
    this.contactPhone,
  });

  factory AdminCamp.fromJson(JsonMap json) {
    final contact = asJsonMap(json['contact']);
    return AdminCamp(
      id: asStringOr(json['id'], ''),
      name: asStringOr(json['name'], ''),
      description: asString(json['description']),
      location: GeoPoint.tryFromJson(json['location']) ?? const GeoPoint(latitude: 0, longitude: 0),
      address: asStringOr(json['address'], ''),
      services: asStringList(json['services']),
      contactName: asString(contact['name']),
      contactPhone: asString(contact['phone']),
      startDateTime: asDateTime(json['startDateTime']) ?? DateTime.now(),
      endDateTime: asDateTime(json['endDateTime']) ?? DateTime.now(),
      isActive: asBool(json['isActive']),
      lifecycle: CampLifecycle.fromApi(json['lifecycle']),
    );
  }

  final String id;
  final String name;
  final String? description;
  final GeoPoint location;
  final String address;
  final List<String> services;
  final String? contactName;
  final String? contactPhone;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isActive;
  final CampLifecycle lifecycle;
}

/// Editable camp fields sent to the API.
class CampDraft {
  const CampDraft({
    required this.name,
    required this.location,
    required this.address,
    required this.startDateTime,
    required this.endDateTime,
    required this.isActive,
    this.description = '',
    this.services = const [],
    this.contactName = '',
    this.contactPhone = '',
  });

  final String name;
  final String description;
  final GeoPoint location;
  final String address;
  final List<String> services;
  final String contactName;
  final String contactPhone;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isActive;

  JsonMap toJson() => {
    'name': name,
    'description': description,
    ...location.toJson(),
    'address': address,
    'services': services,
    'contact': {'name': contactName, 'phone': contactPhone},
    'startDateTime': startDateTime.toUtc().toIso8601String(),
    'endDateTime': endDateTime.toUtc().toIso8601String(),
    'isActive': isActive,
  };
}
