import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Compact pill that communicates a status with a semantic [AppTone].
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = AppTone.neutral,
    this.icon,
    this.showDot = false,
  });

  final String label;
  final AppTone tone;
  final IconData? icon;

  /// A small live-status dot (e.g. volunteer ACTIVE).
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette.tone(tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: colors.background, borderRadius: AppRadii.pillAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: AppSpacing.sm,
              height: AppSpacing.sm,
              decoration: BoxDecoration(color: colors.foreground, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xs + AppSpacing.xxs),
          ] else if (icon != null) ...[
            Icon(icon, size: AppSizes.iconSm, color: colors.foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.labelMedium?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
