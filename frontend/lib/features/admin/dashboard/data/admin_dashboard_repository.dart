import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/utils/json.dart';
import '../domain/admin_dashboard.dart';

class AdminDashboardRepository {
  const AdminDashboardRepository(this._api);

  final ApiClient _api;

  Future<AdminDashboard> fetch() =>
      _api.get('/admin/dashboard', decode: (data) => AdminDashboard.fromJson(asJsonMap(data)));
}

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>(
  (ref) => AdminDashboardRepository(ref.watch(apiClientProvider)),
);
