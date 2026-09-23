import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'app_card.dart';

/// Tappable shortcut tile (icon, title, subtitle, chevron) for dashboards.
class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.tone = AppTone.brand,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final AppTone tone;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette.tone(tone);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: AppSizes.avatarMd,
            height: AppSizes.avatarMd,
            decoration: BoxDecoration(color: colors.background, borderRadius: AppRadii.mdAll),
            child: Icon(icon, color: colors.foreground),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.titleSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(subtitle!, style: context.textStyles.bodySmall),
                ],
              ],
            ),
          ),
          trailing ?? Icon(Icons.chevron_right_rounded, color: context.palette.textMuted),
        ],
      ),
    );
  }
}
