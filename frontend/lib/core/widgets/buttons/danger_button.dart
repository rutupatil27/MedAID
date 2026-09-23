import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Full-width emergency-coloured action (e.g. "Send alert now").
/// Use sparingly: the emergency colour is reserved for emergency actions.
class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  /// Outlined variant for destructive-but-secondary actions (e.g. cancel alert).
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final foreground = outlined ? palette.emergency : palette.onEmergency;

    final Widget child = isLoading
        ? SizedBox.square(
            dimension: AppSizes.iconMd,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: foreground),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSizes.iconMd),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    final onTap = isLoading ? null : onPressed;
    final button = outlined
        ? OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.emergency,
              side: BorderSide(color: palette.emergency, width: 1.4),
            ),
            child: child,
          )
        : FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: palette.emergency,
              foregroundColor: palette.onEmergency,
            ),
            child: child,
          );

    return SizedBox(width: double.infinity, child: button);
  }
}
