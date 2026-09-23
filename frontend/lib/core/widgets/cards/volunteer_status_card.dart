import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../chips/status_chip.dart';
import 'app_card.dart';

/// Volunteer availability summary with an optional Active/Offline switch.
class VolunteerStatusCard extends StatelessWidget {
  const VolunteerStatusCard({
    super.key,
    required this.title,
    required this.statusLabel,
    required this.statusTone,
    this.message,
    this.switchValue,
    this.onSwitchChanged,
    this.switchSemanticLabel,
    this.isUpdating = false,
    this.onTap,
  });

  final String title;
  final String statusLabel;
  final AppTone statusTone;
  final String? message;

  /// When non-null a switch is shown (true = available).
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final String? switchSemanticLabel;
  final bool isUpdating;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                StatusChip(label: statusLabel, tone: statusTone, showDot: true),
                if (message != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(message!, style: context.textStyles.bodySmall),
                ],
              ],
            ),
          ),
          if (switchValue != null) ...[
            const SizedBox(width: AppSpacing.md),
            if (isUpdating)
              const SizedBox.square(
                dimension: AppSizes.iconLg,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            else
              Semantics(
                label: switchSemanticLabel,
                child: Switch(value: switchValue!, onChanged: onSwitchChanged),
              ),
          ],
        ],
      ),
    );
  }
}
