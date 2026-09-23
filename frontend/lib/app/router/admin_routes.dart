import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/layout/bottom_nav_bar.dart';
import '../../features/admin/camps/presentation/screens/admin_camps_screen.dart';
import '../../features/admin/camps/presentation/screens/camp_form_screen.dart';
import '../../features/admin/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/emergencies/presentation/screens/admin_emergencies_screen.dart';
import '../../features/admin/emergencies/presentation/screens/admin_emergency_detail_screen.dart';
import '../../features/admin/reports/presentation/screens/admin_reports_screen.dart';
import '../../features/admin/settings/presentation/screens/admin_more_screen.dart';
import '../../features/admin/users/presentation/screens/admin_users_screen.dart';
import '../../features/admin/volunteers/domain/document_preview.dart';
import '../../features/admin/volunteers/presentation/screens/admin_volunteer_detail_screen.dart';
import '../../features/admin/volunteers/presentation/screens/admin_volunteers_screen.dart';
import '../../features/admin/volunteers/presentation/screens/create_volunteer_screen.dart';
import '../../features/admin/volunteers/presentation/screens/document_viewer_screen.dart';
import '../../features/admin/volunteers/presentation/screens/volunteer_tracking_screen.dart';
import '../../features/auth/presentation/screens/edit_account_screen.dart';
import '../localization/generated/app_localizations.dart';
import 'app_routes.dart';
import 'route_helpers.dart';

/// Admin console: Dashboard, Emergencies, Volunteers, Camps, More.
RouteBase adminShellRoute(GlobalKey<NavigatorState> root) {
  GoRoute page(String path, Widget Function(GoRouterState state) build) =>
      fullScreenRoute(root, path, build);

  return StatefulShellRoute.indexedStack(
    builder: (context, state, shell) {
      final l10n = AppLocalizations.of(context);
      return RoleShellScaffold(
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
            label: l10n.navVolunteers,
            icon: Icons.groups_outlined,
            selectedIcon: Icons.groups_rounded,
          ),
          NavItem(
            label: l10n.navCamps,
            icon: Icons.medical_services_outlined,
            selectedIcon: Icons.medical_services_rounded,
          ),
          NavItem(
            label: l10n.navMore,
            icon: Icons.menu_rounded,
            selectedIcon: Icons.menu_open_rounded,
          ),
        ],
      );
    },
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(path: AppRoutes.adminHome, builder: (_, _) => const AdminDashboardScreen()),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.adminEmergencies,
            builder: (_, _) => const AdminEmergenciesScreen(),
            routes: [
              page(':id', (s) => AdminEmergencyDetailScreen(emergencyId: s.pathParameters['id']!)),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.adminVolunteers,
            builder: (_, _) => const AdminVolunteersScreen(),
            routes: [
              page('new', (_) => const CreateVolunteerScreen()),
              page('tracking', (_) => const VolunteerTrackingScreen()),
              page(':id', (s) => AdminVolunteerDetailScreen(volunteerId: s.pathParameters['id']!)),
              page(
                ':id/document',
                (s) => DocumentViewerScreen(preview: s.extra as DocumentPreview?),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.adminCamps,
            builder: (_, _) => const AdminCampsScreen(),
            routes: [
              page('new', (_) => const CampFormScreen()),
              page(':id', (s) => CampFormScreen(campId: s.pathParameters['id'])),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.adminMore,
            builder: (_, _) => const AdminMoreScreen(),
            routes: [
              page('users', (_) => const AdminUsersScreen()),
              page('reports', (_) => const AdminReportsScreen()),
              page('profile', (_) => const EditAccountScreen()),
            ],
          ),
        ],
      ),
    ],
  );
}
