import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Vertical list of short statements with a leading icon.
class BulletList extends StatelessWidget {
  const BulletList({
    super.key,
    required this.items,
    this.icon = Icons.check_circle_outline_rounded,
    this.tone = AppTone.brand,
  });

  final List<String> items;
  final IconData icon;
  final AppTone tone;

  @override
  Widget build(BuildContext context) {
    final color = context.palette.tone(tone).foreground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Icon(icon, size: AppSizes.iconMd, color: color),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(item, style: context.textStyles.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}
