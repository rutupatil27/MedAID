import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import 'admin_routes.dart';
import 'app_routes.dart';
import 'route_guard.dart';
import 'user_routes.dart';
import 'volunteer_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  // Bridges Riverpod auth state into GoRouter's refresh mechanism.
  final authState = ValueNotifier<AsyncValue<AuthState>>(ref.read(authProvider));
  ref.listen(authProvider, (_, next) => authState.value = next);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: authState,
    redirect: (context, state) =>
        resolveRedirect(auth: authState.value, location: state.matchedLocation),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(path: AppRoutes.changePassword, builder: (_, _) => const ChangePasswordScreen()),
      GoRoute(
        path: AppRoutes.accountPassword,
        builder: (_, _) => const ChangePasswordScreen(forced: false),
      ),
      GoRoute(path: AppRoutes.notifications, builder: (_, _) => const NotificationCenterScreen()),
      userShellRoute(rootNavigatorKey),
      volunteerShellRoute(rootNavigatorKey),
      adminShellRoute(rootNavigatorKey),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authState.dispose();
  });
  return router;
});
