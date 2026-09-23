import '../../shared/enums/user_role.dart';

/// Route paths. Screens navigate with these constants only.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const changePassword = '/change-password';

  /// Voluntary password change, available to every role.
  static const accountPassword = '/account/password';

  /// Notification center, shared by every role (P-16).
  static const notifications = '/notifications';

  // ---- User ----------------------------------------------------------------
  static const userHome = '/user';
  static const userFacilities = '/user/facilities';
  static const userEmergencies = '/user/emergencies';
  static const userProfile = '/user/profile';
  static const userSymptoms = '/user/symptoms';
  static const userSymptomResult = '/user/symptoms/result';
  static const userSos = '/user/sos';
  static const userProfileEdit = '/user/profile/edit';
  static const userMedicalProfile = '/user/profile/medical';
  static const userLanguage = '/user/profile/language';

  static String userFacility(String type, String id) =>
      '/user/facilities/${type.toLowerCase()}/$id';

  static String userEmergency(String id) => '/user/emergencies/$id';

  // ---- Volunteer -----------------------------------------------------------
  static const volunteerHome = '/volunteer';
  static const volunteerEmergencies = '/volunteer/emergencies';
  static const volunteerProfile = '/volunteer/profile';
  static const volunteerCompleteProfile = '/volunteer/onboarding/profile';
  static const volunteerDocuments = '/volunteer/onboarding/documents';
  static const volunteerVerification = '/volunteer/verification';

  static String volunteerEmergency(String id) => '/volunteer/emergencies/$id';

  // ---- Admin ---------------------------------------------------------------
  static const adminHome = '/admin';
  static const adminEmergencies = '/admin/emergencies';
  static const adminVolunteers = '/admin/volunteers';
  static const adminVolunteerCreate = '/admin/volunteers/new';
  static const adminTracking = '/admin/volunteers/tracking';
  static const adminCamps = '/admin/camps';
  static const adminCampCreate = '/admin/camps/new';
  static const adminMore = '/admin/more';
  static const adminUsers = '/admin/more/users';
  static const adminReports = '/admin/more/reports';
  static const adminProfileEdit = '/admin/more/profile';

  static String adminEmergency(String id) => '/admin/emergencies/$id';

  static String adminVolunteer(String id) => '/admin/volunteers/$id';

  /// Document viewer; the document itself travels as `extra`.
  static String adminVolunteerDocument(String id) => '/admin/volunteers/$id/document';

  static String adminCamp(String id) => '/admin/camps/$id';

  static String homeFor(UserRole role) => switch (role) {
    UserRole.user => userHome,
    UserRole.volunteer => volunteerHome,
    UserRole.admin => adminHome,
  };
}
