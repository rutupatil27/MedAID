import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/push_service.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/notification_providers.dart';

/// Connects incoming pushes to the UI (doc 19): a tapped notification opens
/// its screen, after sign-in if needed. A push that arrives while the app is
/// in the foreground refreshes the unread badge, which is what the user sees
/// (the system tray shows nothing while the app is open); the live screens
/// poll for the change itself (P-09).
class PushScope extends ConsumerStatefulWidget {
  const PushScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushScope> createState() => _PushScopeState();
}

class _PushScopeState extends ConsumerState<PushScope> {
  final _subscriptions = <StreamSubscription<PushMessage>>[];

  /// A tap that arrived before the session was restored.
  PushMessage? _pending;

  @override
  void initState() {
    super.initState();
    final push = ref.read(pushServiceProvider);
    if (!push.isEnabled) return;
    _subscriptions
      ..add(push.onMessageOpened.listen(_open))
      ..add(push.onForegroundMessage.listen((_) => ref.invalidate(unreadCountProvider)));
    push.initialMessage().then((message) {
      if (message != null && mounted) _open(message);
    }).ignore();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  bool _openNow(PushMessage message) => ref
      .read(notificationOpenerProvider)
      .open(type: message.type, data: message.data, notificationId: message.notificationId);

  void _open(PushMessage message) {
    if (!_openNow(message)) _pending = message;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (_, _) {
      if (_pending == null) return;
      // Let the router leave the splash screen first, then open on top of home.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pending = _pending;
        if (mounted && pending != null && _openNow(pending)) _pending = null;
      });
    });
    return widget.child;
  }
}
