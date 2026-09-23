import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/utils/live_polling.dart';
import '../../../shared/models/emergency.dart';
import '../../../shared/models/geo_point.dart';
import '../../../shared/models/response_route.dart';
import '../data/volunteer_repository.dart';
import 'volunteer_controller.dart';

/// Emergencies currently dispatched to this volunteer (0 or 1). Polls so a new
/// dispatch appears even when a push notification is delayed.
class ActiveAssignmentsController extends AsyncNotifier<List<Emergency>>
    with LivePolling<List<Emergency>> {
  @override
  Future<List<Emergency>> fetchLatest() async =>
      (await ref.read(volunteerRepositoryProvider).emergencies(EmergencyScope.active)).items;

  @override
  bool shouldPoll(List<Emergency> value) => true;

  @override
  Future<List<Emergency>> build() async {
    final items = await fetchLatest();
    startPolling(items);
    return items;
  }
}

final activeAssignmentsProvider =
    AsyncNotifierProvider.autoDispose<ActiveAssignmentsController, List<Emergency>>(
      ActiveAssignmentsController.new,
    );

final volunteerHistoryProvider = FutureProvider.autoDispose<Paged<Emergency>>(
  (ref) => ref.watch(volunteerRepositoryProvider).emergencies(EmergencyScope.history),
);

/// One dispatched emergency with the volunteer's response actions.
class VolunteerEmergencyController extends AsyncNotifier<Emergency> with LivePolling<Emergency> {
  VolunteerEmergencyController(this.emergencyId);

  final String emergencyId;

  VolunteerRepository get _repository => ref.read(volunteerRepositoryProvider);

  @override
  Future<Emergency> fetchLatest() => _repository.emergency(emergencyId);

  @override
  bool shouldPoll(Emergency value) => value.isOpen && (value.assignment?.status.isActive ?? false);

  @override
  Future<Emergency> build() async {
    final emergency = await fetchLatest();
    startPolling(emergency);
    return emergency;
  }

  Future<void> accept() => _apply(() => _repository.accept(emergencyId));

  Future<void> decline({String? reason}) =>
      _apply(() => _repository.decline(emergencyId, reason: reason));

  Future<void> start() => _apply(() => _repository.start(emergencyId));

  Future<void> resolve(String note) => _apply(() => _repository.resolve(emergencyId, note));

  Future<void> _apply(Future<Emergency> Function() action) async {
    final updated = await action();
    if (!ref.mounted) return;
    state = AsyncData(updated);
    schedulePoll(updated);
    // Accept/resolve change the volunteer's availability (ACTIVE <-> BUSY).
    ref
      ..invalidate(activeAssignmentsProvider)
      ..invalidate(volunteerHistoryProvider)
      ..invalidate(volunteerProvider);
  }
}

final volunteerEmergencyProvider = AsyncNotifierProvider.autoDispose
    .family<VolunteerEmergencyController, Emergency, String>(VolunteerEmergencyController.new);

/// Route/ETA to an emergency the volunteer is responding to. Watch it only
/// while the assignment is active; it refreshes slowly to respect routing quotas.
class VolunteerRouteController extends AsyncNotifier<ResponseRoute>
    with LivePolling<ResponseRoute> {
  VolunteerRouteController(this.emergencyId);

  final String emergencyId;

  @override
  Duration get pollInterval => AppConfig.routeRefreshInterval;

  @override
  Future<ResponseRoute> fetchLatest() => ref.read(volunteerRepositoryProvider).route(emergencyId);

  @override
  bool shouldPoll(ResponseRoute value) => true;

  @override
  Future<ResponseRoute> build() async {
    final route = await fetchLatest();
    startPolling(route);
    return route;
  }
}

final volunteerRouteProvider = AsyncNotifierProvider.autoDispose
    .family<VolunteerRouteController, ResponseRoute, String>(VolunteerRouteController.new);
