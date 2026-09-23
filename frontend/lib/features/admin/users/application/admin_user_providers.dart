import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/value_controller.dart';
import '../../../../shared/enums/user_role.dart';
import '../../../../shared/models/app_user.dart';
import '../data/admin_user_repository.dart';

final adminUserRoleFilterProvider = NotifierProvider<ValueController<UserRole?>, UserRole?>(
  () => ValueController(UserRole.user),
);

final adminUserSearchProvider = NotifierProvider<ValueController<String>, String>(
  () => ValueController(''),
);

class AdminUsersController extends AsyncNotifier<List<AppUser>> {
  @override
  Future<List<AppUser>> build() async =>
      (await ref
              .watch(adminUserRepositoryProvider)
              .list(
                role: ref.watch(adminUserRoleFilterProvider),
                search: ref.watch(adminUserSearchProvider),
              ))
          .items;

  Future<void> setSuspended(String userId, {required bool suspended}) async {
    await ref.read(adminUserRepositoryProvider).setSuspended(userId, suspended: suspended);
    if (ref.mounted) ref.invalidateSelf();
  }
}

final adminUsersProvider = AsyncNotifierProvider.autoDispose<AdminUsersController, List<AppUser>>(
  AdminUsersController.new,
);
