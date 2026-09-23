import '../../../../core/utils/json.dart';
import '../../../../shared/models/geo_point.dart';

enum FacilityType {
  hospital('HOSPITAL'),
  camp('CAMP');

  const FacilityType(this.apiValue);

  final String apiValue;

  static FacilityType fromApi(Object? value) =>
      value == 'CAMP' || value == 'camp' ? FacilityType.camp : FacilityType.hospital;
}

enum FacilityFilter { all, hospitals, camps }

/// Hospital or currently valid temporary medical camp.
class Facility {
  const Facility({
    required this.id,
    required this.type,
    required this.name,
    required this.location,
    this.address,
    this.description,
    this.distanceMeters,
    this.services = const [],
    this.contactName,
    this.contactPhone,
    this.hasEmergencyDepartment = false,
    this.startDateTime,
    this.endDateTime,
  });

  factory Facility.fromJson(JsonMap json) {
    final contact = asJsonMap(json['contact']);
    return Facility(
      id: asStringOr(json['id'], ''),
      type: FacilityType.fromApi(json['type']),
      name: asStringOr(json['name'], ''),
      location: GeoPoint.tryFromJson(json['location']) ?? const GeoPoint(latitude: 0, longitude: 0),
      address: asString(json['address']),
      description: asString(json['description']),
      distanceMeters: asDouble(json['distanceMeters']),
      services: asStringList(json['services']),
      contactName: asString(contact['name']),
      contactPhone: asString(contact['phone']),
      hasEmergencyDepartment: asBool(json['hasEmergencyDepartment']),
      startDateTime: asDateTime(json['startDateTime']),
      endDateTime: asDateTime(json['endDateTime']),
    );
  }

  final String id;
  final FacilityType type;
  final String name;
  final GeoPoint location;
  final String? address;
  final String? description;
  final double? distanceMeters;
  final List<String> services;
  final String? contactName;
  final String? contactPhone;
  final bool hasEmergencyDepartment;
  final DateTime? startDateTime;
  final DateTime? endDateTime;

  bool get isCamp => type == FacilityType.camp;
}
