import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/layout/bottom_nav_bar.dart';
import '../../features/auth/presentation/screens/edit_account_screen.dart';
import '../../features/user/emergency/presentation/screens/emergency_detail_screen.dart';
import '../../features/user/emergency/presentation/screens/emergency_history_screen.dart';
import '../../features/user/emergency/presentation/screens/sos_screen.dart';
import '../../features/user/facilities/domain/facility.dart';
import '../../features/user/facilities/presentation/screens/facility_details_screen.dart';
import '../../features/user/facilities/presentation/screens/nearby_facilities_screen.dart';
import '../../features/user/home/presentation/screens/user_home_screen.dart';
import '../../features/user/profile/presentation/screens/language_screen.dart';
import '../../features/user/profile/presentation/screens/medical_profile_screen.dart';
import '../../features/user/profile/presentation/screens/user_profile_screen.dart';
import '../../features/user/symptoms/presentation/screens/symptom_checker_screen.dart';
import '../../features/user/symptoms/presentation/screens/symptom_result_screen.dart';
import '../localization/generated/app_localizations.dart';
import 'app_routes.dart';
import 'route_helpers.dart';

/// User area: four tabs; detail and flow screens open above the tab bar.
RouteBase userShellRoute(GlobalKey<NavigatorState> root) {
  GoRoute fullScreen(String path, Widget Function(GoRouterState state) build) =>
      fullScreenRoute(root, path, build);

  return StatefulShellRoute.indexedStack(
    builder: (context, state, shell) {
      final l10n = AppLocalizations.of(context);
      return RoleShellScaffold(
        navigationShell: shell,
        items: [
          NavItem(label: l10n.navHome, icon: Icons.home_outlined, selectedIcon: Icons.home_rounded),
          NavItem(
            label: l10n.navFacilities,
            icon: Icons.local_hospital_outlined,
            selectedIcon: Icons.local_hospital_rounded,
          ),
          NavItem(
            label: l10n.navEmergencies,
            icon: Icons.notifications_active_outlined,
            selectedIcon: Icons.notifications_active_rounded,
          ),
          NavItem(
            label: l10n.navProfile,
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
        ],
      );
    },
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.userHome,
            builder: (_, _) => const UserHomeScreen(),
            routes: [
              fullScreen('symptoms', (_) => const SymptomCheckerScreen()),
              fullScreen('symptoms/result', (_) => const SymptomResultScreen()),
              fullScreen('sos', (_) => const SosScreen()),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.userFacilities,
            builder: (_, _) => const NearbyFacilitiesScreen(),
            routes: [
              fullScreen(
                ':type/:id',
                (state) => FacilityDetailsScreen(
                  type: FacilityType.fromApi(state.pathParameters['type']),
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.userEmergencies,
            builder: (_, _) => const EmergencyHistoryScreen(),
            routes: [
              fullScreen(
                ':id',
                (state) => EmergencyDetailScreen(emergencyId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.userProfile,
            builder: (_, _) => const UserProfileScreen(),
            routes: [
              fullScreen('edit', (_) => const EditAccountScreen()),
              fullScreen('medical', (_) => const MedicalProfileScreen()),
              fullScreen('language', (_) => const LanguageScreen()),
            ],
          ),
        ],
      ),
    ],
  );
}
