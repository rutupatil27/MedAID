import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../location/location_service.dart';
import '../../theme/app_theme.dart';
import 'permission_prompt.dart';

/// Explains a missing location permission or disabled location services and
/// offers the right fix. [onRetry] should re-request the location.
class LocationAccessPrompt extends ConsumerWidget {
  const LocationAccessPrompt({super.key, required this.access, required this.onRetry});

  final LocationAccess access;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final service = ref.read(locationServiceProvider);
    final servicesOff = access == LocationAccess.serviceDisabled;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: PermissionPrompt(
          icon: servicesOff ? Icons.location_off_rounded : Icons.location_on_rounded,
          title: servicesOff ? l10n.locationServicesOffTitle : l10n.locationPermissionTitle,
          message: servicesOff ? l10n.locationServicesOffMessage : l10n.locationPermissionMessage,
          grantLabel: servicesOff ? l10n.commonOpenSettings : l10n.commonAllow,
          onGrant: () async {
            if (servicesOff) await service.openLocationSettings();
            onRetry();
          },
          settingsLabel: access == LocationAccess.deniedForever ? l10n.commonOpenSettings : null,
          onOpenSettings: access == LocationAccess.deniedForever ? service.openAppSettings : null,
        ),
      ),
    );
  }
}
