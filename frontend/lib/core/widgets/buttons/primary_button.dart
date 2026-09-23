import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Main call-to-action. Shows a spinner and blocks taps while [isLoading].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final foreground = context.colors.onPrimary;
    final child = isLoading
        ? SizedBox.square(
            dimension: AppSizes.iconMd,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: foreground),
          )
        : _ButtonLabel(label: label, icon: icon);

    final button = FilledButton(onPressed: isLoading ? null : onPressed, child: child);
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) return Text(label, textAlign: TextAlign.center);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconMd),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
  }
}
