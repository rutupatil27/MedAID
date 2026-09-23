import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';
import '../cards/app_card.dart';

/// Explains why a permission (location, notifications) is needed and offers
/// to grant it or open system settings.
class PermissionPrompt extends StatelessWidget {
  const PermissionPrompt({
    super.key,
    required this.title,
    required this.message,
    required this.grantLabel,
    required this.onGrant,
    this.icon = Icons.location_on_rounded,
    this.settingsLabel,
    this.onOpenSettings,
  });

  final String title;
  final String message;
  final String grantLabel;
  final VoidCallback onGrant;
  final IconData icon;
  final String? settingsLabel;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette.tone(AppTone.warning);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.background,
                child: Icon(icon, color: colors.foreground),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: context.textStyles.titleSmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: context.textStyles.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: grantLabel, onPressed: onGrant),
          if (settingsLabel != null && onOpenSettings != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(label: settingsLabel!, onPressed: onOpenSettings),
          ],
        ],
      ),
    );
  }
}
