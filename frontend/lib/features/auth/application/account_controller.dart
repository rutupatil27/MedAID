import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/locale_provider.dart';
import '../../../shared/models/app_user.dart';
import '../data/account_repository.dart';
import 'auth_controller.dart';

/// Fresh copy of the signed-in account for profile screens. Every change is
/// mirrored into [authProvider] so the whole app sees it.
class AccountController extends AsyncNotifier<AppUser> {
  AccountRepository get _repository => ref.read(accountRepositoryProvider);

  @override
  Future<AppUser> build() => ref.watch(accountRepositoryProvider).fetch();

  Future<void> updateDetails({required String name, required String phone}) =>
      _apply(() => _repository.update(name: name, phone: phone));

  Future<void> updateMedicalProfile(MedicalProfile profile) =>
      _apply(() => _repository.update(medicalProfile: profile));

  /// Applies the language locally first (works offline), then syncs it.
  Future<void> changeLanguage(Locale locale) async {
    await ref.read(localeProvider.notifier).setLocale(locale);
    await _apply(() => _repository.update(preferredLanguage: locale.languageCode));
  }

  Future<void> _apply(Future<AppUser> Function() request) async {
    final updated = await request();
    if (!ref.mounted) return;
    state = AsyncData(updated);
    ref.read(authProvider.notifier).updateUser(updated);
  }
}

final accountProvider = AsyncNotifierProvider.autoDispose<AccountController, AppUser>(
  AccountController.new,
);
