import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/live_polling.dart';
import '../../../../shared/models/emergency.dart';
import '../../../../shared/models/geo_point.dart';
import '../data/user_emergency_repository.dart';

/// The user's currently open emergency, if any (shown on Home).
final openEmergencyProvider = FutureProvider.autoDispose<Emergency?>((ref) async {
  final page = await ref.watch(userEmergencyRepositoryProvider).listMine(open: true, limit: 1);
  return page.items.isEmpty ? null : page.items.first;
});

final emergencyHistoryProvider = FutureProvider.autoDispose<Paged<Emergency>>(
  (ref) => ref.watch(userEmergencyRepositoryProvider).listMine(),
);

/// Live emergency status for the reporting User; polls while the alert is open.
class EmergencyDetailController extends AsyncNotifier<Emergency> with LivePolling<Emergency> {
  EmergencyDetailController(this.emergencyId);

  final String emergencyId;

  UserEmergencyRepository get _repository => ref.read(userEmergencyRepositoryProvider);

  @override
  Future<Emergency> fetchLatest() => _repository.byId(emergencyId);

  @override
  bool shouldPoll(Emergency value) => value.isOpen;

  @override
  Future<Emergency> build() async {
    final emergency = await fetchLatest();
    startPolling(emergency);
    return emergency;
  }

  Future<void> cancel({String? reason}) async {
    final cancelled = await _repository.cancel(emergencyId, reason: reason);
    if (!ref.mounted) return;
    state = AsyncData(cancelled);
    schedulePoll(cancelled);
    ref
      ..invalidate(openEmergencyProvider)
      ..invalidate(emergencyHistoryProvider);
  }
}

final emergencyDetailProvider = AsyncNotifierProvider.autoDispose
    .family<EmergencyDetailController, Emergency, String>(EmergencyDetailController.new);
