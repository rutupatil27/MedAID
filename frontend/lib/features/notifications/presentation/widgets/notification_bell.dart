import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../application/notification_providers.dart';

/// Header action opening the notification center, with the unread count.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final unread = ref.watch(unreadCountProvider).value ?? 0;

    return IconButton(
      key: const Key('notifications.bell'),
      tooltip: l10n.notificationsBellLabel(unread),
      onPressed: () => context.push(AppRoutes.notifications),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? l10n.notificationsBadgeMax : unread.toString()),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
