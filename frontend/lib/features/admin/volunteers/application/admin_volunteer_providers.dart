import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/live_polling.dart';
import '../../../../core/utils/value_controller.dart';
import '../../../../shared/enums/volunteer_enums.dart';
import '../../../../shared/models/volunteer.dart';
import '../../dashboard/application/admin_dashboard_provider.dart';
import '../data/admin_volunteer_repository.dart';

final adminVolunteerFilterProvider =
    NotifierProvider<ValueController<VolunteerFilter>, VolunteerFilter>(
      () => ValueController(const VolunteerFilter()),
    );

class AdminVolunteersController extends AsyncNotifier<List<Volunteer>> {
  AdminVolunteerRepository get _repository => ref.read(adminVolunteerRepositoryProvider);

  @override
  Future<List<Volunteer>> build() async =>
      (await ref
              .watch(adminVolunteerRepositoryProvider)
              .list(ref.watch(adminVolunteerFilterProvider)))
          .items;

  /// Creates a volunteer account; returns the one-time temporary password.
  Future<({Volunteer volunteer, String temporaryPassword})> create({
    required String name,
    required String email,
    required String username,
    String? phone,
  }) async {
    final repository = _repository;
    final result = await repository.create(
      name: name,
      email: email,
      username: username,
      phone: phone,
    );
    // Opened from a screen that may not be watching the list: refresh only if alive.
    if (ref.mounted) ref.invalidateSelf();
    return result;
  }
}

final adminVolunteersProvider =
    AsyncNotifierProvider.autoDispose<AdminVolunteersController, List<Volunteer>>(
      AdminVolunteersController.new,
    );

/// One volunteer with review and suspension actions.
class AdminVolunteerController extends AsyncNotifier<Volunteer> {
  AdminVolunteerController(this.volunteerId);

  final String volunteerId;

  AdminVolunteerRepository get _repository => ref.read(adminVolunteerRepositoryProvider);

  @override
  Future<Volunteer> build() => ref.watch(adminVolunteerRepositoryProvider).get(volunteerId);

  Future<void> approve() => _apply(() => _repository.verify(volunteerId));

  Future<void> reject(String reason) => _apply(() => _repository.reject(volunteerId, reason));

  Future<void> setSuspended({required bool suspended}) =>
      _apply(() => _repository.setSuspended(volunteerId, suspended: suspended));

  Future<void> _apply(Future<Volunteer> Function() action) async {
    final updated = await action();
    if (!ref.mounted) return;
    state = AsyncData(updated);
    ref
      ..invalidate(adminVolunteersProvider)
      ..invalidate(adminVolunteerDocumentsProvider(volunteerId))
      ..invalidate(adminDashboardProvider);
  }
}

final adminVolunteerProvider = AsyncNotifierProvider.autoDispose
    .family<AdminVolunteerController, Volunteer, String>(AdminVolunteerController.new);

final adminVolunteerDocumentsProvider = FutureProvider.autoDispose
    .family<List<ReviewDocument>, String>(
      (ref, id) => ref.watch(adminVolunteerRepositoryProvider).documents(id),
    );

/// Active, verified volunteers an admin may assign manually.
final assignableVolunteersProvider = FutureProvider.autoDispose<List<Volunteer>>((ref) async {
  final page = await ref
      .watch(adminVolunteerRepositoryProvider)
      .list(
        const VolunteerFilter(
          verificationStatus: VerificationStatus.approved,
          status: VolunteerStatus.active,
        ),
      );
  return page.items;
});

/// Live volunteer positions (admin only, doc 18).
class VolunteerPinsController extends AsyncNotifier<List<VolunteerPin>>
    with LivePolling<List<VolunteerPin>> {
  @override
  Future<List<VolunteerPin>> fetchLatest() =>
      ref.read(adminVolunteerRepositoryProvider).locations();

  @override
  bool shouldPoll(List<VolunteerPin> value) => true;

  @override
  Duration get pollInterval => const Duration(seconds: 10);

  @override
  Future<List<VolunteerPin>> build() async {
    final pins = await fetchLatest();
    startPolling(pins);
    return pins;
  }
}

final volunteerPinsProvider =
    AsyncNotifierProvider.autoDispose<VolunteerPinsController, List<VolunteerPin>>(
      VolunteerPinsController.new,
    );
