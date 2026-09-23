import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../chips/status_chip.dart';
import 'app_card.dart';

/// Emergency alert summary used by User history, Volunteer lists and Admin
/// monitoring. Callers supply localized labels.
class EmergencyCard extends StatelessWidget {
  const EmergencyCard({
    super.key,
    required this.title,
    required this.statusLabel,
    required this.statusTone,
    required this.timeLabel,
    this.subtitle,
    this.details = const [],
    this.highlight = false,
    this.trailing,
    this.onTap,
  });

  /// e.g. the alert number "MED-20260917-0042".
  final String title;
  final String statusLabel;
  final AppTone statusTone;
  final String timeLabel;
  final String? subtitle;

  /// Short icon + text facts (distance, assigned volunteer, attempts...).
  final List<({IconData icon, String text})> details;

  /// Draws an emergency border for alerts that need attention now.
  final bool highlight;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AppCard(
      onTap: onTap,
      borderColor: highlight ? palette.emergency : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emergency_rounded,
                color: highlight ? palette.emergency : palette.textSecondary,
                size: AppSizes.iconMd,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleSmall,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(label: statusLabel, tone: statusTone),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle!, style: context.textStyles.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              _Fact(icon: Icons.schedule_rounded, text: timeLabel),
              for (final detail in details) _Fact(icon: detail.icon, text: detail.text),
            ],
          ),
          if (trailing != null) ...[const SizedBox(height: AppSpacing.md), trailing!],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconSm, color: context.palette.textMuted),
        const SizedBox(width: AppSpacing.xs),
        Text(text, style: context.textStyles.bodySmall),
      ],
    );
  }
}
