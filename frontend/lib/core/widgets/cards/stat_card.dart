import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'app_card.dart';

/// Single metric tile for dashboards.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone = AppTone.brand,
    this.caption,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final AppTone tone;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette.tone(tone);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: colors.background, borderRadius: AppRadii.mdAll),
            child: Icon(icon, color: colors.foreground, size: AppSizes.iconLg),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: context.textStyles.headlineSmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodySmall,
          ),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              caption!,
              style: context.textStyles.labelSmall?.copyWith(color: colors.foreground),
            ),
          ],
        ],
      ),
    );
  }
}
