import '../../core/utils/json.dart';
import '../enums/volunteer_enums.dart';
import 'geo_point.dart';

class VolunteerProfile {
  const VolunteerProfile({
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.city,
    this.languages = const [],
    this.skills = const [],
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  factory VolunteerProfile.fromJson(JsonMap json) => VolunteerProfile(
    phone: asString(json['phone']),
    dateOfBirth: asDateTime(json['dateOfBirth']),
    gender: asString(json['gender']),
    address: asString(json['address']),
    city: asString(json['city']),
    languages: asStringList(json['languages']),
    skills: asStringList(json['skills']),
    emergencyContactName: asString(json['emergencyContactName']),
    emergencyContactPhone: asString(json['emergencyContactPhone']),
  );

  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final String? city;
  final List<String> languages;
  final List<String> skills;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
}

class VolunteerDocumentInfo {
  const VolunteerDocumentInfo({
    required this.id,
    required this.type,
    required this.status,
    required this.uploadedAt,
    this.originalName,
    this.mimeType,
    this.sizeBytes,
    this.reviewNote,
  });

  factory VolunteerDocumentInfo.fromJson(JsonMap json) => VolunteerDocumentInfo(
    id: asStringOr(json['id'], ''),
    type: DocumentType.fromApi(json['documentType']),
    status: DocumentStatus.fromApi(json['status']),
    uploadedAt: asDateTime(json['uploadedAt']) ?? DateTime.now(),
    originalName: asString(json['originalName']),
    mimeType: asString(json['mimeType']),
    sizeBytes: asInt(json['sizeBytes']),
    reviewNote: asString(json['reviewNote']),
  );

  final String id;
  final DocumentType type;
  final DocumentStatus status;
  final DateTime uploadedAt;
  final String? originalName;
  final String? mimeType;
  final int? sizeBytes;
  final String? reviewNote;
}

class VolunteerLocation {
  const VolunteerLocation({
    required this.point,
    this.accuracy,
    this.updatedAt,
    this.isStale = true,
  });

  static VolunteerLocation? tryFromJson(Object? value) {
    final point = GeoPoint.tryFromJson(value);
    if (point == null) return null;
    final json = asJsonMap(value);
    return VolunteerLocation(
      point: point,
      accuracy: asDouble(json['accuracy']),
      updatedAt: asDateTime(json['updatedAt']),
      isStale: asBool(json['isStale'], fallback: true),
    );
  }

  final GeoPoint point;
  final double? accuracy;
  final DateTime? updatedAt;
  final bool isStale;
}

class VolunteerAccount {
  const VolunteerAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    this.phone,
    this.accountStatus = 'ACTIVE',
  });

  factory VolunteerAccount.fromJson(JsonMap json) => VolunteerAccount(
    id: asStringOr(json['id'], ''),
    name: asStringOr(json['name'], ''),
    email: asStringOr(json['email'], ''),
    username: asStringOr(json['username'], ''),
    phone: asString(json['phone']),
    accountStatus: asStringOr(json['accountStatus'], 'ACTIVE'),
  );

  final String id;
  final String name;
  final String email;
  final String username;
  final String? phone;
  final String accountStatus;

  bool get isSuspended => accountStatus == 'SUSPENDED';
}

/// A volunteer as seen by themself and by admins.
class Volunteer {
  const Volunteer({
    required this.id,
    required this.account,
    required this.profile,
    required this.profileCompleted,
    required this.verificationStatus,
    required this.status,
    this.submittedAt,
    this.verifiedAt,
    this.rejectionReason,
    this.location,
    this.currentEmergencyId,
    this.lastActiveAt,
    this.requiredDocuments = const [DocumentType.idProof, DocumentType.firstAidCertificate],
    this.documents = const [],
  });

  factory Volunteer.fromJson(JsonMap json) => Volunteer(
    id: asStringOr(json['id'], ''),
    account: VolunteerAccount.fromJson(asJsonMap(json['user'])),
    profile: VolunteerProfile.fromJson(asJsonMap(json['profile'])),
    profileCompleted: asBool(json['profileCompleted']),
    verificationStatus: VerificationStatus.fromApi(json['verificationStatus']),
    status: VolunteerStatus.fromApi(json['status']),
    submittedAt: asDateTime(json['submittedAt']),
    verifiedAt: asDateTime(json['verifiedAt']),
    rejectionReason: asString(json['rejectionReason']),
    location: VolunteerLocation.tryFromJson(json['location']),
    currentEmergencyId: asString(json['currentEmergencyId']),
    lastActiveAt: asDateTime(json['lastActiveAt']),
    requiredDocuments: asStringList(json['requiredDocuments']).map(DocumentType.fromApi).toList(),
    documents: asJsonList(json['documents']).map(VolunteerDocumentInfo.fromJson).toList(),
  );

  final String id;
  final VolunteerAccount account;
  final VolunteerProfile profile;
  final bool profileCompleted;
  final VerificationStatus verificationStatus;
  final VolunteerStatus status;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final VolunteerLocation? location;
  final String? currentEmergencyId;
  final DateTime? lastActiveAt;
  final List<DocumentType> requiredDocuments;
  final List<VolunteerDocumentInfo> documents;

  bool get isApproved => verificationStatus == VerificationStatus.approved;

  VolunteerDocumentInfo? documentOf(DocumentType type) {
    for (final doc in documents) {
      if (doc.type == type) return doc;
    }
    return null;
  }

  bool get hasAllDocuments => requiredDocuments.every(
    (type) => documentOf(type) != null && documentOf(type)!.status != DocumentStatus.rejected,
  );
}
