import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../../app/localization/locale_provider.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/enums/volunteer_enums.dart';
import '../../../shared/models/volunteer.dart';
import '../data/volunteer_repository.dart';
import 'volunteer_controller.dart';

enum TrackingStatus { off, tracking, unavailable }

class LocationTrackingState {
  const LocationTrackingState({
    this.status = TrackingStatus.off,
    this.access,
    this.lastFix,
    this.lastSentAt,
  });

  final TrackingStatus status;

  /// Why tracking is [TrackingStatus.unavailable].
  final LocationAccess? access;

  /// Latest device fix (also shown on the response map).
  final LocationFix? lastFix;

  /// When the backend last accepted a location from this device.
  final DateTime? lastSentAt;

  LocationTrackingState copyWith({LocationFix? lastFix, DateTime? lastSentAt}) =>
      LocationTrackingState(
        status: status,
        access: access,
        lastFix: lastFix ?? this.lastFix,
        lastSentAt: lastSentAt ?? this.lastSentAt,
      );
}

/// Tracking tunables (OQ-32). Overridden in tests with short durations.
class TrackingConfig {
  const TrackingConfig({
    this.distanceFilterMeters = AppConfig.trackingDistanceFilterMeters,
    this.interval = AppConfig.trackingInterval,
    this.heartbeat = AppConfig.trackingHeartbeat,
    this.minSendGap = AppConfig.trackingMinSendGap,
  });

  final int distanceFilterMeters;
  final Duration interval;

  /// Sends a fresh fix when nothing was sent since the last beat, so a
  /// stationary volunteer's location never goes stale.
  final Duration heartbeat;

  /// Movement updates closer together than this are coalesced.
  final Duration minSendGap;
}

final trackingConfigProvider = Provider<TrackingConfig>((ref) => const TrackingConfig());

/// Shares the volunteer's live location with the backend while they are
/// ACTIVE or BUSY, and stops as soon as they go OFFLINE (doc 18, OQ-32).
///
/// On Android the stream runs as a foreground service with a persistent
/// notification, so it continues while the app is in the background. Nothing
/// runs once the app is closed: the stored location then goes stale and the
/// engine stops dispatching to this volunteer, which is the safe outcome.
class LocationTrackingController extends Notifier<LocationTrackingState> {
  StreamSubscription<LocationFix>? _subscription;
  Timer? _heartbeat;
  Timer? _cooldown;
  LocationFix? _pending;
  bool _wanted = false;
  bool _sentSinceBeat = false;

  static bool shouldTrack(Volunteer? v) =>
      v != null &&
      v.isApproved &&
      (v.status == VolunteerStatus.active || v.status == VolunteerStatus.busy);

  LocationService get _location => ref.read(locationServiceProvider);

  TrackingConfig get _config => ref.read(trackingConfigProvider);

  @override
  LocationTrackingState build() {
    ref.onDispose(_teardown);
    ref.listen(
      volunteerProvider.select((value) => shouldTrack(value.value)),
      (_, track) => track ? _start() : _stop(),
    );
    if (shouldTrack(ref.read(volunteerProvider).value)) unawaited(_start());
    return const LocationTrackingState();
  }

  /// Call after the user grants permission or turns location services on.
  Future<void> retry() async {
    _stop();
    if (shouldTrack(ref.read(volunteerProvider).value)) await _start();
  }

  Future<void> _start() async {
    if (_wanted) return;
    _wanted = true;
    final access = await _location.checkAccess();
    if (!_wanted) return;
    if (access != LocationAccess.granted) {
      _markUnavailable(access);
      return;
    }

    final l10n = lookupAppLocalizations(ref.read(localeProvider));
    _subscription = _location
        .watch(
          distanceFilterMeters: _config.distanceFilterMeters,
          interval: _config.interval,
          foregroundNotificationTitle: l10n.trackingNotificationTitle,
          foregroundNotificationText: l10n.trackingNotificationText,
        )
        .listen(_onFix, onError: (_) => _onStreamError());
    _heartbeat = Timer.periodic(_config.heartbeat, (_) => _beat());
    state = LocationTrackingState(
      status: TrackingStatus.tracking,
      lastFix: state.lastFix,
      lastSentAt: state.lastSentAt,
    );
    await _beat(); // Report immediately, e.g. when the app restarts while BUSY.
  }

  void _onFix(LocationFix fix) {
    if (!_wanted) return;
    state = state.copyWith(lastFix: fix);
    if (_cooldown?.isActive ?? false) {
      _pending = fix;
      return;
    }
    unawaited(_send(fix));
  }

  Future<void> _beat() async {
    if (_sentSinceBeat) {
      _sentSinceBeat = false;
      return;
    }
    final fix = await _location.currentFix();
    if (!_wanted || fix == null) return;
    state = state.copyWith(lastFix: fix);
    await _send(fix, fromHeartbeat: true);
  }

  Future<void> _send(LocationFix fix, {bool fromHeartbeat = false}) async {
    if (!fromHeartbeat) _sentSinceBeat = true;
    _pending = null;
    _cooldown?.cancel();
    _cooldown = Timer(_config.minSendGap, () {
      final pending = _pending;
      if (pending != null && _wanted) unawaited(_send(pending));
    });
    try {
      await ref.read(volunteerRepositoryProvider).updateLocation(fix);
      if (_wanted) state = state.copyWith(lastSentAt: DateTime.now());
    } on ApiException catch (error) {
      // Went offline or was suspended elsewhere: refreshing the profile
      // stops tracking through the listener in build.
      if (_wanted && error.code == ApiErrorCodes.volunteerNotAvailable) {
        ref.read(volunteerProvider.notifier).refresh().ignore();
      }
    } catch (_) {
      // Network trouble: the next movement or heartbeat retries.
    }
  }

  Future<void> _onStreamError() async {
    final access = await _location.checkAccess();
    if (!_wanted) return;
    _markUnavailable(access == LocationAccess.granted ? LocationAccess.serviceDisabled : access);
  }

  /// Keeps checking so tracking resumes once the user fixes the problem in
  /// system settings.
  void _markUnavailable(LocationAccess access) {
    _cancelTimers();
    state = LocationTrackingState(
      status: TrackingStatus.unavailable,
      access: access,
      lastFix: state.lastFix,
      lastSentAt: state.lastSentAt,
    );
    _heartbeat = Timer.periodic(_config.heartbeat, (_) async {
      if (await _location.checkAccess() == LocationAccess.granted && _wanted) await retry();
    });
  }

  void _stop() {
    _teardown();
    state = const LocationTrackingState();
  }

  void _cancelTimers() {
    _subscription?.cancel();
    _subscription = null;
    _heartbeat?.cancel();
    _heartbeat = null;
    _cooldown?.cancel();
    _cooldown = null;
    _pending = null;
    _sentSinceBeat = false;
  }

  void _teardown() {
    _wanted = false;
    _cancelTimers();
  }
}

/// Kept alive by [VolunteerDutyScope] around the volunteer shell, so
/// tracking stops when the volunteer signs out.
final locationTrackingProvider =
    NotifierProvider.autoDispose<LocationTrackingController, LocationTrackingState>(
      LocationTrackingController.new,
    );
