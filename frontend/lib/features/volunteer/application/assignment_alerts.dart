import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/localization/locale_provider.dart';
import '../../../app/router/app_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/notifications/alert_actions.dart';
import '../../../core/notifications/background_alerts.dart';
import '../../../core/notifications/local_notifier.dart';
import '../../../shared/enums/volunteer_enums.dart';
import '../../../shared/models/emergency.dart';
import '../data/volunteer_repository.dart';
import 'location_tracking_controller.dart';
import 'volunteer_controller.dart';
import 'volunteer_emergency_providers.dart';

/// Alerts the volunteer with a system notification, sound and vibration the
/// moment an emergency is dispatched to them — they have two minutes to
/// answer and cannot be expected to watch the screen.
///
/// An unanswered emergency keeps ringing until it is accepted, declined, or it
/// expires, because one beep in a noisy crowd is easy to miss. The tone loops
/// in the notification channel itself, played by Android; this controller only
/// re-raises the banner every [AppConfig.alertRepeatInterval] so it stays in
/// front of the volunteer. The alert carries Accept and Decline buttons, so
/// answering never needs the app to be found and opened first.
///
/// Raised by the app itself, so it works without Firebase, and it covers what
/// push cannot: an app that is already open. The same alert is raised from a
/// background isolate when the app is not running — see `background_alerts.dart`.
class AssignmentAlertsController extends Notifier<void> {
  /// Assignment id -> notification id, for the alerts on screen now.
  final _showing = <String, int>{};
  final _emergencyOf = <String, String>{};

  /// Emergencies answered from the notification. The list can still show them
  /// as waiting for a moment afterwards, and ringing again then would be
  /// wrong.
  final _answered = <String>{};
  StreamSubscription<AlertResponse>? _responses;
  Timer? _ring;

  /// Captured during build: timers, streams and dispose callbacks run at
  /// moments when reading a provider is not allowed.
  late LocalNotifier _notifier;

  VolunteerRepository get _repository => ref.read(volunteerRepositoryProvider);

  @override
  void build() {
    _notifier = ref.read(localNotifierProvider);

    ref.onDispose(() {
      _responses?.cancel();
      _responses = null;
      _ring?.cancel();
      _ring = null;
    });

    // Only while on duty: an offline or unverified volunteer receives no
    // dispatches, so there is nothing to watch for or to interrupt them with.
    final onDuty = ref.watch(
      volunteerProvider.select((v) => LocationTrackingController.shouldTrack(v.value)),
    );
    if (!onDuty) {
      _withdrawAll();
      return;
    }

    ref.listen(activeAssignmentsProvider, (_, next) {
      final assignments = next.value;
      if (assignments != null) _sync(assignments);
    });

    unawaited(_start());
  }

  Future<void> _start() async {
    await _notifier.initialize();
    // Android 13+ needs this; refusing only costs the sound, not the app.
    await _notifier.requestPermission();
    _responses ??= _notifier.onOpened.listen(_respond);
    final current = ref.read(activeAssignmentsProvider).value;
    if (current != null) _sync(current);
  }

  bool _isWaiting(Emergency emergency) =>
      emergency.isOpen && emergency.assignment?.status == AssignmentStatus.pending;

  void _sync(List<Emergency> assignments) {
    final waiting = {
      for (final emergency in assignments)
        if (_isWaiting(emergency) &&
            emergency.assignment != null &&
            !_answered.contains(emergency.id))
          emergency.assignment!.id: emergency,
    };
    // Forget answers once the server agrees they are no longer waiting.
    _answered.removeWhere(
      (emergencyId) => !assignments.any((e) => e.id == emergencyId && _isWaiting(e)),
    );

    for (final entry in waiting.entries) {
      if (_showing.containsKey(entry.key)) continue;
      final notificationId = alertNotificationId(entry.key);
      _showing[entry.key] = notificationId;
      _emergencyOf[entry.key] = entry.value.id;
      unawaited(_alert(notificationId, entry.value));
    }

    // Accepted, declined or expired elsewhere: take the alert away.
    for (final assignmentId in _showing.keys.toList()) {
      if (waiting.containsKey(assignmentId)) continue;
      unawaited(_notifier.cancel(_showing.remove(assignmentId)!));
      _emergencyOf.remove(assignmentId);
    }

    _keepRinging(waiting);
  }

  /// Re-raises the alert while anything is still waiting.
  ///
  /// The tone itself loops in the notification channel, played by Android, so
  /// this only has to keep the heads-up banner in front of the volunteer — and
  /// to ring again if they managed to dismiss the notification.
  void _keepRinging(Map<String, Emergency> waiting) {
    if (waiting.isEmpty) {
      _ring?.cancel();
      _ring = null;
      return;
    }
    _ring ??= Timer.periodic(AppConfig.alertRepeatInterval, (_) {
      for (final entry in waiting.entries) {
        final notificationId = _showing[entry.key];
        if (notificationId != null) unawaited(_alert(notificationId, entry.value));
      }
    });
  }

  Future<void> _alert(int notificationId, Emergency emergency) async {
    final l10n = lookupAppLocalizations(ref.read(localeProvider));
    await _notifier.showAlert(
      id: notificationId,
      title: l10n.volunteerAlertNotificationTitle,
      body: l10n.volunteerAlertNotificationBody,
      payload: emergency.id,
      ongoing: true,
      actions: [
        AlertAction(id: acceptAction, label: l10n.volunteerAccept),
        AlertAction(id: declineAction, label: l10n.volunteerDecline),
      ],
    );
  }

  /// Answers straight from the notification, or opens the emergency when the
  /// notification itself was tapped.
  Future<void> _respond(AlertResponse response) async {
    final emergencyId = response.payload;
    if (emergencyId.isEmpty) return;

    if (response.actionId == null) {
      unawaited(ref.read(routerProvider).push(AppRoutes.volunteerEmergency(emergencyId)));
      return;
    }

    _stopRinging(emergencyId);
    try {
      if (response.actionId == acceptAction) {
        await _repository.accept(emergencyId);
        unawaited(ref.read(routerProvider).push(AppRoutes.volunteerEmergency(emergencyId)));
      } else if (response.actionId == declineAction) {
        await _repository.decline(emergencyId);
      }
    } catch (_) {
      // Expired or taken by someone else: the list refresh below shows why.
    } finally {
      ref
        ..invalidate(activeAssignmentsProvider)
        ..invalidate(volunteerProvider);
    }
  }

  /// Silences the alert for one emergency as soon as it is answered, without
  /// waiting for the next poll to confirm it.
  void _stopRinging(String emergencyId) {
    _answered.add(emergencyId);
    for (final entry in _emergencyOf.entries.toList()) {
      if (entry.value != emergencyId) continue;
      final notificationId = _showing.remove(entry.key);
      _emergencyOf.remove(entry.key);
      if (notificationId != null) unawaited(_notifier.cancel(notificationId));
    }
    if (_showing.isEmpty) {
      _ring?.cancel();
      _ring = null;
    }
  }

  void _withdrawAll() {
    for (final notificationId in _showing.values) {
      unawaited(_notifier.cancel(notificationId));
    }
    _showing.clear();
    _emergencyOf.clear();
    _answered.clear();
    _ring?.cancel();
    _ring = null;
  }
}

/// Kept alive by [VolunteerDutyScope] around the volunteer shell.
final assignmentAlertsProvider = NotifierProvider.autoDispose<AssignmentAlertsController, void>(
  AssignmentAlertsController.new,
);
