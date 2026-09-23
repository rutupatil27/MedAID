import '../../../shared/models/app_user.dart';
import '../../../shared/models/auth_tokens.dart';

sealed class AuthState {
  const AuthState();
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

final class Authenticated extends AuthState {
  const Authenticated(this.user);

  final AppUser user;
}

/// Result of login/register/refresh/change-password.
class AuthSession {
  const AuthSession({required this.user, required this.tokens});

  final AppUser user;
  final AuthTokens tokens;
}
