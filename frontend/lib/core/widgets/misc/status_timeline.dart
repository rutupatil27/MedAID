import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class TimelineItem {
  const TimelineItem({
    required this.label,
    required this.time,
    this.detail,
    this.tone = AppTone.neutral,
  });

  final String label;
  final String time;

  /// Why this step happened, when there is something to say. Repeated steps
  /// are only distinguishable by this.
  final String? detail;
  final AppTone tone;
}

/// Vertical status history (newest last), used for emergency lifecycles.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.items});

  final List<TimelineItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: AppSpacing.xl,
                  child: Column(
                    children: [
                      Container(
                        width: AppSpacing.md,
                        height: AppSpacing.md,
                        margin: const EdgeInsets.only(top: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: context.palette.tone(items[i].tone).foreground,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (i < items.length - 1)
                        Expanded(child: Container(width: 2, color: context.palette.border)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(items[i].label, style: context.textStyles.titleSmall),
                            ),
                            Text(items[i].time, style: context.textStyles.bodySmall),
                          ],
                        ),
                        if (items[i].detail case final detail?)
                          Text(
                            detail,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: context.palette.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
