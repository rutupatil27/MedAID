import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/value_controller.dart';
import '../data/admin_camp_repository.dart';
import '../domain/admin_camp.dart';

/// Null shows every camp.
final adminCampFilterProvider = NotifierProvider<ValueController<CampLifecycle?>, CampLifecycle?>(
  () => ValueController(null),
);

class AdminCampsController extends AsyncNotifier<List<AdminCamp>> {
  AdminCampRepository get _repository => ref.read(adminCampRepositoryProvider);

  @override
  Future<List<AdminCamp>> build() async =>
      (await ref
              .watch(adminCampRepositoryProvider)
              .list(lifecycle: ref.watch(adminCampFilterProvider)))
          .items;

  Future<AdminCamp> save(CampDraft draft, {String? id}) async {
    final repository = _repository;
    final saved = id == null ? await repository.create(draft) : await repository.update(id, draft);
    if (ref.mounted) ref.invalidateSelf();
    return saved;
  }

  Future<void> delete(String id) async {
    final repository = _repository;
    await repository.delete(id);
    if (ref.mounted) ref.invalidateSelf();
  }
}

final adminCampsProvider = AsyncNotifierProvider.autoDispose<AdminCampsController, List<AdminCamp>>(
  AdminCampsController.new,
);

final adminCampProvider = FutureProvider.autoDispose.family<AdminCamp, String>(
  (ref, id) => ref.watch(adminCampRepositoryProvider).get(id),
);
