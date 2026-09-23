import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medaid/app/router/app_routes.dart';
import 'package:medaid/app/router/route_guard.dart';
import 'package:medaid/features/auth/domain/auth_state.dart';
import 'package:medaid/shared/models/app_user.dart';

import '../helpers/fakes.dart';

AsyncValue<AuthState> signedIn(String role, {bool mustChangePassword = false}) => AsyncData(
  Authenticated(AppUser.fromJson(userJson(role: role, mustChangePassword: mustChangePassword))),
);

void main() {
  group('resolveRedirect', () {
    test('holds on splash while the session is restoring or failed', () {
      expect(
        resolveRedirect(auth: const AsyncLoading(), location: AppRoutes.login),
        AppRoutes.splash,
      );
      expect(resolveRedirect(auth: const AsyncLoading(), location: AppRoutes.splash), isNull);
      expect(
        resolveRedirect(
          auth: AsyncError(Exception('offline'), StackTrace.empty),
          location: AppRoutes.userHome,
        ),
        AppRoutes.splash,
      );
    });

    test('sends signed-out visitors to login but allows register', () {
      const out = AsyncData<AuthState>(Unauthenticated());
      expect(resolveRedirect(auth: out, location: AppRoutes.adminHome), AppRoutes.login);
      expect(resolveRedirect(auth: out, location: AppRoutes.register), isNull);
      expect(resolveRedirect(auth: out, location: AppRoutes.login), isNull);
    });

    test('lands each role on its own home', () {
      expect(
        resolveRedirect(auth: signedIn('USER'), location: AppRoutes.login),
        AppRoutes.userHome,
      );
      expect(
        resolveRedirect(auth: signedIn('VOLUNTEER'), location: AppRoutes.splash),
        AppRoutes.volunteerHome,
      );
      expect(
        resolveRedirect(auth: signedIn('ADMIN'), location: AppRoutes.register),
        AppRoutes.adminHome,
      );
    });

    test('blocks access to another role area', () {
      expect(
        resolveRedirect(auth: signedIn('USER'), location: '${AppRoutes.adminHome}/volunteers'),
        AppRoutes.userHome,
      );
      expect(
        resolveRedirect(auth: signedIn('VOLUNTEER'), location: AppRoutes.userHome),
        AppRoutes.volunteerHome,
      );
      expect(
        resolveRedirect(auth: signedIn('ADMIN'), location: '${AppRoutes.adminHome}/camps'),
        isNull,
      );
    });

    test('does not confuse similarly prefixed paths', () {
      expect(resolveRedirect(auth: signedIn('USER'), location: '/users-guide'), isNull);
    });

    test('forces a password change before anything else', () {
      final auth = signedIn('VOLUNTEER', mustChangePassword: true);
      expect(
        resolveRedirect(auth: auth, location: AppRoutes.volunteerHome),
        AppRoutes.changePassword,
      );
      expect(resolveRedirect(auth: auth, location: AppRoutes.changePassword), isNull);
    });
  });
}
