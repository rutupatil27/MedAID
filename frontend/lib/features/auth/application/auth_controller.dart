import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/locale_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/notifications/device_registration.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/models/app_user.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

/// Owns the session. Screens call these methods; errors propagate as
/// [ApiException] so the calling screen can show a localized message.
class AuthController extends AsyncNotifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);
  TokenStorage get _tokens => ref.read(tokenStorageProvider);

  @override
  Future<AuthState> build() async {
    final subscription = ref
        .read(sessionExpiredEventsProvider)
        .stream
        .listen((_) => state = const AsyncData(Unauthenticated()));
    ref.onDispose(subscription.cancel);

    final stored = await _tokens.read();
    if (stored == null) return const Unauthenticated();

    try {
      final user = await _repository.fetchCurrentUser();
      _registerDevice(user);
      return Authenticated(user);
    } on ApiException catch (error) {
      if (error.isUnauthorized || error.code == ApiErrorCodes.accountSuspended) {
        await _tokens.clear();
        return const Unauthenticated();
      }
      rethrow; // e.g. offline at startup: splash offers a retry
    }
  }

  Future<void> login({required String identifier, required String password}) async {
    final session = await _repository.login(identifier: identifier, password: password);
    await _startSession(session, applyLanguage: true);
  }

  Future<void> register({
    required String name,
    required String email,
    required String username,
    required String password,
    String? phone,
  }) async {
    final session = await _repository.register(
      name: name,
      email: email,
      username: username,
      password: password,
      phone: phone,
      preferredLanguage: ref.read(localeProvider).languageCode,
    );
    await _startSession(session);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final session = await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    await _startSession(session);
  }

  Future<void> logout() async {
    // While the session is still valid, so the server accepts the removal.
    await ref.read(deviceRegistrationProvider).unregister();
    final stored = await _tokens.read();
    if (stored != null) {
      try {
        await _repository.logout(stored.refreshToken);
      } on ApiException {
        // Logging out locally must always succeed, even offline.
      }
    }
    await _tokens.clear();
    state = const AsyncData(Unauthenticated());
  }

  /// Keeps the session user in sync after profile edits.
  void updateUser(AppUser user) {
    if (state.value is Authenticated) state = AsyncData(Authenticated(user));
  }

  Future<void> retry() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> _startSession(AuthSession session, {bool applyLanguage = false}) async {
    await _tokens.save(session.tokens);
    if (applyLanguage) {
      await ref.read(localeProvider.notifier).setLocale(Locale(session.user.preferredLanguage));
    }
    state = AsyncData(Authenticated(session.user));
    _registerDevice(session.user);
  }

  /// Push registration is best effort and never delays the session.
  void _registerDevice(AppUser user) {
    // The server refuses everything but a password change until it is done.
    if (user.mustChangePassword) return;
    unawaited(ref.read(deviceRegistrationProvider).register());
  }
}

final authProvider = AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);
