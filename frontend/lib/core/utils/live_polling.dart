import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_config.dart';

/// Periodic refresh for live AsyncNotifiers (P-09: push + polling).
///
/// Call [startPolling] with the first value from `build`. Polling continues
/// while [shouldPoll] is true, keeps the last good data visible when a poll
/// fails, and stops automatically when the provider is disposed.
mixin LivePolling<T> on AsyncNotifier<T> {
  Timer? _pollTimer;

  Future<T> fetchLatest();

  bool shouldPoll(T value);

  Duration get pollInterval => AppConfig.livePollInterval;

  void startPolling(T value) {
    ref.onDispose(stopPolling);
    schedulePoll(value);
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Reschedules based on [value]; call after any local state change.
  void schedulePoll(T value, {Duration? delay}) {
    _pollTimer?.cancel();
    if (!shouldPoll(value)) return;
    _pollTimer = Timer(delay ?? pollInterval, _poll);
  }

  Future<void> _poll() async {
    try {
      final latest = await fetchLatest();
      if (!ref.mounted) return;
      state = AsyncData(latest);
      schedulePoll(latest);
    } catch (_) {
      if (!ref.mounted) return;
      final current = state.value;
      if (current != null) schedulePoll(current, delay: pollInterval * 2);
    }
  }
}
