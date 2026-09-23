import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/live_polling.dart';
import '../../../../core/utils/value_controller.dart';
import '../../../../shared/models/emergency.dart';
import '../data/admin_emergency_repository.dart';

final adminEmergencyFilterProvider =
    NotifierProvider<ValueController<AdminEmergencyFilter>, AdminEmergencyFilter>(
      () => ValueController(AdminEmergencyFilter.open),
    );

final adminEmergencySearchProvider = NotifierProvider<ValueController<String>, String>(
  () => ValueController(''),
);

/// Monitored emergencies for the current filter; polls for live updates.
class AdminEmergenciesController extends AsyncNotifier<List<Emergency>>
    with LivePolling<List<Emergency>> {
  @override
  Future<List<Emergency>> fetchLatest() async =>
      (await ref
              .read(adminEmergencyRepositoryProvider)
              .list(
                ref.read(adminEmergencyFilterProvider),
                search: ref.read(adminEmergencySearchProvider),
              ))
          .items;

  @override
  bool shouldPoll(List<Emergency> value) => true;

  @override
  Future<List<Emergency>> build() async {
    ref
      ..watch(adminEmergencyFilterProvider)
      ..watch(adminEmergencySearchProvider);
    final items = await fetchLatest();
    startPolling(items);
    return items;
  }
}

final adminEmergenciesProvider =
    AsyncNotifierProvider.autoDispose<AdminEmergenciesController, List<Emergency>>(
      AdminEmergenciesController.new,
    );

/// One emergency with admin overrides (reassign, resolve, cancel).
class AdminEmergencyController extends AsyncNotifier<Emergency> with LivePolling<Emergency> {
  AdminEmergencyController(this.emergencyId);

  final String emergencyId;

  AdminEmergencyRepository get _repository => ref.read(adminEmergencyRepositoryProvider);

  @override
  Future<Emergency> fetchLatest() => _repository.get(emergencyId);

  @override
  bool shouldPoll(Emergency value) => value.isOpen;

  @override
  Future<Emergency> build() async {
    final emergency = await fetchLatest();
    startPolling(emergency);
    return emergency;
  }

  Future<void> reassign({String? volunteerId}) =>
      _apply(() => _repository.reassign(emergencyId, volunteerId: volunteerId));

  Future<void> resolve(String note) => _apply(() => _repository.resolve(emergencyId, note));

  Future<void> cancel(String note) => _apply(() => _repository.cancel(emergencyId, note));

  Future<void> _apply(Future<Emergency> Function() action) async {
    final updated = await action();
    if (!ref.mounted) return;
    state = AsyncData(updated);
    schedulePoll(updated);
    ref.invalidate(adminEmergenciesProvider);
  }
}

final adminEmergencyProvider = AsyncNotifierProvider.autoDispose
    .family<AdminEmergencyController, Emergency, String>(AdminEmergencyController.new);
