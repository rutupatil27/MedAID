import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../core/widgets/dialogs/confirmation_dialog.dart';
import '../application/auth_controller.dart';

/// Confirms, then logs out. Shared by every role's profile screen.
Future<void> confirmAndLogout(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showConfirmationDialog(
    context,
    title: l10n.authLogoutConfirmTitle,
    message: l10n.authLogoutConfirmMessage,
    confirmLabel: l10n.authLogout,
  );
  if (confirmed) await ref.read(authProvider.notifier).logout();
}
