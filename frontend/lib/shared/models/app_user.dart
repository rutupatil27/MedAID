import '../../core/utils/json.dart';
import '../enums/user_role.dart';

/// Optional medical information a User may share with responders.
class MedicalProfile {
  const MedicalProfile({
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.allergies,
    this.medicalConditions,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.shareWithResponders = false,
  });

  factory MedicalProfile.fromJson(JsonMap json) => MedicalProfile(
    dateOfBirth: asDateTime(json['dateOfBirth']),
    gender: asString(json['gender']),
    bloodGroup: asString(json['bloodGroup']),
    allergies: asString(json['allergies']),
    medicalConditions: asString(json['medicalConditions']),
    emergencyContactName: asString(json['emergencyContactName']),
    emergencyContactPhone: asString(json['emergencyContactPhone']),
    shareWithResponders: asBool(json['shareWithResponders']),
  );

  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? allergies;
  final String? medicalConditions;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final bool shareWithResponders;

  JsonMap toJson() => {
    'dateOfBirth': dateOfBirth?.toUtc().toIso8601String(),
    'gender': gender,
    'bloodGroup': bloodGroup,
    'allergies': allergies ?? '',
    'medicalConditions': medicalConditions ?? '',
    'emergencyContactName': emergencyContactName ?? '',
    'emergencyContactPhone': emergencyContactPhone ?? '',
    'shareWithResponders': shareWithResponders,
  };
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.role,
    this.phone,
    this.accountStatus = AccountStatus.active,
    this.preferredLanguage = 'en',
    this.mustChangePassword = false,
    this.medicalProfile = const MedicalProfile(),
  });

  factory AppUser.fromJson(JsonMap json) => AppUser(
    id: asStringOr(json['id'], ''),
    name: asStringOr(json['name'], ''),
    email: asStringOr(json['email'], ''),
    username: asStringOr(json['username'], ''),
    phone: asString(json['phone']),
    role: UserRole.fromApi(json['role']),
    accountStatus: AccountStatus.fromApi(json['accountStatus']),
    preferredLanguage: asStringOr(json['preferredLanguage'], 'en'),
    mustChangePassword: asBool(json['mustChangePassword']),
    medicalProfile: MedicalProfile.fromJson(asJsonMap(json['medicalProfile'])),
  );

  final String id;
  final String name;
  final String email;
  final String username;
  final String? phone;
  final UserRole role;
  final AccountStatus accountStatus;
  final String preferredLanguage;
  final bool mustChangePassword;
  final MedicalProfile medicalProfile;
}
