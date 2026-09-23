import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/live_polling.dart';
import '../../reports/data/admin_report_repository.dart';
import '../data/admin_dashboard_repository.dart';
import '../domain/admin_dashboard.dart';

/// Control-room snapshot, refreshed while visible.
class AdminDashboardController extends AsyncNotifier<AdminDashboard>
    with LivePolling<AdminDashboard> {
  @override
  Future<AdminDashboard> fetchLatest() => ref.read(adminDashboardRepositoryProvider).fetch();

  @override
  bool shouldPoll(AdminDashboard value) => true;

  @override
  Duration get pollInterval => const Duration(seconds: 10);

  @override
  Future<AdminDashboard> build() async {
    final dashboard = await fetchLatest();
    startPolling(dashboard);
    return dashboard;
  }
}

final adminDashboardProvider =
    AsyncNotifierProvider.autoDispose<AdminDashboardController, AdminDashboard>(
      AdminDashboardController.new,
    );

final adminReportProvider = FutureProvider.autoDispose<ReportSummary>(
  (ref) => ref.watch(adminReportRepositoryProvider).summary(),
);
