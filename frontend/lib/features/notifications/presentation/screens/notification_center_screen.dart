import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/widgets/dialogs/app_snackbar.dart';
import '../../../../core/widgets/empty_states/empty_state_view.dart';
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../shared/models/app_notification.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/auth_state.dart';
import '../../application/notification_links.dart';
import '../../application/notification_providers.dart';
import '../widgets/notification_tile.dart';

/// Notification Center (doc 27, user #13), shared by every role.
class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  void _open(BuildContext context, WidgetRef ref, AppNotification notification) {
    ref.read(notificationsProvider.notifier).markRead(notification).ignore();
    final auth = ref.read(authProvider).value;
    if (auth is! Authenticated) return;
    final route = notificationRoute(
      role: auth.user.role,
      type: notification.type,
      data: notification.data,
    );
    if (route != null) context.push(route);
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(notificationsProvider.notifier).markAllRead();
    } catch (error) {
      if (context.mounted) {
        showAppSnackbar(context, localizedErrorMessage(l10n, error), tone: AppTone.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final page = ref.watch(notificationsProvider);
    final hasUnread = (page.value?.unreadCount ?? 0) > 0;

    return AppScaffold(
      title: l10n.notificationsTitle,
      scrollable: false,
      actions: [
        if (hasUnread)
          TextButton(
            key: const Key('notifications.markAllRead'),
            onPressed: () => _markAllRead(context, ref),
            child: Text(l10n.notificationsMarkAllRead),
          ),
      ],
      body: AsyncValueView<NotificationPage>(
        value: page,
        onRetry: () => ref.invalidate(notificationsProvider),
        isEmpty: (p) => p.items.isEmpty,
        empty: EmptyStateView(
          title: l10n.notificationsEmptyTitle,
          message: l10n.notificationsEmptyMessage,
          icon: Icons.notifications_none_rounded,
        ),
        data: (p) => RefreshIndicator(
          onRefresh: () => ref.refresh(notificationsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            itemCount: p.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) => NotificationTile(
              notification: p.items[i],
              onTap: () => _open(context, ref, p.items[i]),
            ),
          ),
        ),
      ),
    );
  }
}
