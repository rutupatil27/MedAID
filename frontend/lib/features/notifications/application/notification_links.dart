import '../../../app/router/app_routes.dart';
import '../../../shared/enums/user_role.dart';

final _objectId = RegExp(r'^[a-f0-9]{24}$');

/// Where tapping a notification leads for the signed-in [role], or null to
/// stay in the notification center.
///
/// Only routes inside the role's own area are produced, and IDs must be well
/// formed. The route guard and the backend still check access: an emergency
/// that is not the account's own returns 404 (doc 19: open the detail screen
/// only after validating authentication and authorization).
String? notificationRoute({
  required UserRole role,
  required String type,
  required Map<String, String> data,
}) {
  String? id(String key) {
    final value = data[key];
    return value != null && _objectId.hasMatch(value) ? value : null;
  }

  final emergencyId = id('emergencyId');
  switch (role) {
    case UserRole.user:
      if (type.startsWith('EMERGENCY_') && emergencyId != null) {
        return AppRoutes.userEmergency(emergencyId);
      }
    case UserRole.volunteer:
      if (type.startsWith('ASSIGNMENT_') && emergencyId != null) {
        return AppRoutes.volunteerEmergency(emergencyId);
      }
      if (type.startsWith('VERIFICATION_')) return AppRoutes.volunteerVerification;
    case UserRole.admin:
      final volunteerId = id('volunteerId');
      if (type == 'VERIFICATION_SUBMITTED' && volunteerId != null) {
        return AppRoutes.adminVolunteer(volunteerId);
      }
      if ((type.startsWith('EMERGENCY_') || type.startsWith('ASSIGNMENT_')) &&
          emergencyId != null) {
        return AppRoutes.adminEmergency(emergencyId);
      }
  }
  return null;
}
