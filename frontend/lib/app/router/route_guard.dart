import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_state.dart';
import '../../shared/enums/user_role.dart';
import 'app_routes.dart';

const _publicRoutes = {AppRoutes.login, AppRoutes.register};

const _roleAreas = {
  UserRole.user: AppRoutes.userHome,
  UserRole.volunteer: AppRoutes.volunteerHome,
  UserRole.admin: AppRoutes.adminHome,
};

bool _isInArea(String location, String area) => location == area || location.startsWith('$area/');

/// Pure redirect policy (client-side guard; the backend still enforces roles).
/// Returns the path to redirect to, or null to allow [location].
String? resolveRedirect({required AsyncValue<AuthState> auth, required String location}) {
  final state = auth.value;
  if (state == null) {
    // Restoring the session, or it failed (splash shows a retry).
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  switch (state) {
    case Unauthenticated():
      return _publicRoutes.contains(location) ? null : AppRoutes.login;

    case Authenticated(:final user):
      if (user.mustChangePassword) {
        return location == AppRoutes.changePassword ? null : AppRoutes.changePassword;
      }
      final home = AppRoutes.homeFor(user.role);
      if (location == AppRoutes.splash ||
          location == AppRoutes.changePassword ||
          _publicRoutes.contains(location)) {
        return home;
      }
      for (final MapEntry(key: role, value: area) in _roleAreas.entries) {
        if (_isInArea(location, area) && role != user.role) return home;
      }
      return null;
  }
}
