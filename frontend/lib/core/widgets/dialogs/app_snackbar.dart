import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Shows a short themed message. Use [AppTone.danger] for failures.
void showAppSnackbar(BuildContext context, String message, {AppTone tone = AppTone.neutral}) {
  final palette = context.palette;
  final (Color? background, IconData? icon) = switch (tone) {
    AppTone.success => (palette.success, Icons.check_circle_rounded),
    AppTone.danger || AppTone.emergency => (context.colors.error, Icons.error_rounded),
    AppTone.warning => (palette.warning, Icons.warning_amber_rounded),
    _ => (null, null),
  };
  final foreground = context.colors.onPrimary;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: background,
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: foreground, size: AppSizes.iconMd),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
