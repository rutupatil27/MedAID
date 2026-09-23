import 'package:flutter/material.dart';

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../shared/models/app_notification.dart';

/// One notification in the center: event icon, text, time and unread dot.
class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  static (AppTone, IconData) _visual(String type) => switch (type) {
    'ASSIGNMENT_NEW' ||
    'ASSIGNMENT_EXPIRING' ||
    'EMERGENCY_CREATED' ||
    'EMERGENCY_UNASSIGNED' ||
    'EMERGENCY_ESCALATED' => (AppTone.emergency, Icons.emergency_rounded),
    'EMERGENCY_ACCEPTED' ||
    'EMERGENCY_IN_PROGRESS' ||
    'EMERGENCY_RESOLVED' ||
    'VERIFICATION_APPROVED' => (AppTone.success, Icons.check_circle_rounded),
    'EMERGENCY_ASSIGNED' || 'EMERGENCY_REASSIGNING' => (AppTone.info, Icons.directions_run_rounded),
    'VERIFICATION_SUBMITTED' => (AppTone.info, Icons.fact_check_rounded),
    'VERIFICATION_REJECTED' || 'ACCOUNT_SUSPENDED' => (AppTone.warning, Icons.report_rounded),
    'ADMIN_NOTICE' => (AppTone.brand, Icons.campaign_rounded),
    _ => (AppTone.neutral, Icons.notifications_rounded),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (tone, icon) = _visual(notification.type);
    final colors = context.palette.tone(tone);
    final unread = !notification.isRead;
    final createdAt = notification.createdAt;

    return Semantics(
      label: unread ? l10n.notificationsUnread : null,
      child: AppCard(
        onTap: onTap,
        borderColor: unread ? colors.foreground : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(color: colors.background, shape: BoxShape.circle),
              child: Icon(icon, color: colors.foreground, size: AppSizes.iconMd),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: context.textStyles.titleSmall?.copyWith(
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(notification.body, style: context.textStyles.bodyMedium),
                  if (createdAt != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppFormatters.of(context).relativeTime(createdAt),
                      style: context.textStyles.labelSmall?.copyWith(
                        color: context.palette.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (unread)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm, top: AppSpacing.xs),
                child: Container(
                  key: const Key('notification.unreadDot'),
                  width: AppSpacing.sm,
                  height: AppSpacing.sm,
                  decoration: BoxDecoration(color: colors.foreground, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
