import 'package:flutter/material.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../buttons/primary_button.dart';

/// Full-area error state with an explicit retry (doc 23).
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tone = context.palette.tone(AppTone.danger);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: AppSizes.avatarMd / 2 + AppSpacing.sm,
                backgroundColor: tone.background,
                child: Icon(icon, color: tone.foreground, size: AppSizes.iconXl),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(message, textAlign: TextAlign.center, style: context.textStyles.bodyLarge),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: l10n.commonRetry,
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                  expand: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
