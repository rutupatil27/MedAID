import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/location/location_service.dart';
import '../../../../shared/models/emergency.dart';
import '../data/user_emergency_repository.dart';
import 'user_emergency_providers.dart';

enum SosStep { idle, locating, sending, sent, failed }

class SosState {
  const SosState({
    this.step = SosStep.idle,
    this.emergency,
    this.error,
    this.locationShared = true,
  });

  final SosStep step;
  final Emergency? emergency;
  final Object? error;
  final bool locationShared;

  bool get isBusy => step == SosStep.locating || step == SosStep.sending;
}

/// Runs the SOS flow: best-effort location (never blocks the alert, OQ-15),
/// then an idempotent create. Retries reuse the same key, so a flaky network
/// cannot create duplicate alerts.
class SosController extends Notifier<SosState> {
  String? _attemptKey;

  @override
  SosState build() => const SosState();

  static String _newKey() {
    final random = Random.secure();
    return List.generate(24, (_) => random.nextInt(16).toRadixString(16)).join();
  }

  Future<void> send() async {
    if (state.isBusy) return;
    _attemptKey ??= 'sos-${_newKey()}';

    state = const SosState(step: SosStep.locating);
    final location = ref.read(locationServiceProvider);
    await location.requestAccess();
    final fix = await location.currentFix(timeout: AppConfig.sosLocationTimeout);
    if (!ref.mounted) return;

    state = SosState(step: SosStep.sending, locationShared: fix != null);
    try {
      final emergency = await ref
          .read(userEmergencyRepositoryProvider)
          .create(idempotencyKey: _attemptKey!, location: fix);
      if (!ref.mounted) return;
      _attemptKey = null;
      ref.invalidate(openEmergencyProvider);
      state = SosState(step: SosStep.sent, emergency: emergency, locationShared: fix != null);
    } catch (error) {
      if (!ref.mounted) return;
      state = SosState(step: SosStep.failed, error: error, locationShared: fix != null);
    }
  }

  void reset() {
    _attemptKey = null;
    state = const SosState();
  }
}

final sosControllerProvider = NotifierProvider.autoDispose<SosController, SosState>(
  SosController.new,
);
