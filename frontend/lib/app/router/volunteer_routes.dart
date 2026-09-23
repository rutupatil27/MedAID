import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/layout/bottom_nav_bar.dart';
import '../../features/volunteer/dashboard/presentation/screens/volunteer_dashboard_screen.dart';
import '../../features/volunteer/emergencies/presentation/screens/volunteer_emergencies_screen.dart';
import '../../features/volunteer/emergencies/presentation/screens/volunteer_emergency_detail_screen.dart';
import '../../features/volunteer/location/presentation/widgets/volunteer_duty_scope.dart';
import '../../features/volunteer/onboarding/presentation/screens/complete_profile_screen.dart';
import '../../features/volunteer/onboarding/presentation/screens/document_upload_screen.dart';
import '../../features/volunteer/profile/presentation/screens/volunteer_profile_screen.dart';
import '../../features/volunteer/verification/presentation/screens/verification_status_screen.dart';
import '../localization/generated/app_localizations.dart';
import 'app_routes.dart';
import 'route_helpers.dart';

/// Volunteer area: Dashboard, Emergencies, Profile.
RouteBase volunteerShellRoute(GlobalKey<NavigatorState> root) {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, shell) {
      final l10n = AppLocalizations.of(context);
      // Live location sharing and emergency alerts run while this area is open.
      return VolunteerDutyScope(
        child: RoleShellScaffold(
          navigationShell: shell,
          items: [
            NavItem(
              label: l10n.navDashboard,
              icon: Icons.space_dashboard_outlined,
              selectedIcon: Icons.space_dashboard_rounded,
            ),
            NavItem(
              label: l10n.navEmergencies,
              icon: Icons.emergency_outlined,
              selectedIcon: Icons.emergency_rounded,
            ),
            NavItem(
              label: l10n.navProfile,
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
            ),
          ],
        ),
      );
    },
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.volunteerHome,
            builder: (_, _) => const VolunteerDashboardScreen(),
            routes: [
              fullScreenRoute(root, 'onboarding/profile', (_) => const CompleteProfileScreen()),
              fullScreenRoute(root, 'onboarding/documents', (_) => const DocumentUploadScreen()),
              fullScreenRoute(root, 'verification', (_) => const VerificationStatusScreen()),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.volunteerEmergencies,
            builder: (_, _) => const VolunteerEmergenciesScreen(),
            routes: [
              fullScreenRoute(
                root,
                ':id',
                (state) => VolunteerEmergencyDetailScreen(emergencyId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.volunteerProfile,
            builder: (_, _) => const VolunteerProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
