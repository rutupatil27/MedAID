import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/utils/json.dart';

class ReportSummary {
  const ReportSummary({
    required this.total,
    required this.resolved,
    required this.cancelled,
    required this.reassigned,
    required this.reassignmentRate,
    required this.perDay,
    this.avgTimeToAcceptSeconds,
    this.avgTimeToResolveSeconds,
  });

  factory ReportSummary.fromJson(JsonMap json) {
    final e = asJsonMap(json['emergencies']);
    return ReportSummary(
      total: asInt(e['total']) ?? 0,
      resolved: asInt(e['resolved']) ?? 0,
      cancelled: asInt(e['cancelled']) ?? 0,
      reassigned: asInt(e['reassigned']) ?? 0,
      reassignmentRate: asDouble(e['reassignmentRate']) ?? 0,
      avgTimeToAcceptSeconds: asInt(e['avgTimeToAcceptSeconds']),
      avgTimeToResolveSeconds: asInt(e['avgTimeToResolveSeconds']),
      perDay: [
        for (final day in asJsonList(json['perDay']))
          (date: asStringOr(day['date'], ''), count: asInt(day['count']) ?? 0),
      ],
    );
  }

  final int total;
  final int resolved;
  final int cancelled;
  final int reassigned;
  final double reassignmentRate;
  final int? avgTimeToAcceptSeconds;
  final int? avgTimeToResolveSeconds;
  final List<({String date, int count})> perDay;
}

class AdminReportRepository {
  const AdminReportRepository(this._api);

  final ApiClient _api;

  Future<ReportSummary> summary() =>
      _api.get('/admin/reports/summary', decode: (data) => ReportSummary.fromJson(asJsonMap(data)));
}

final adminReportRepositoryProvider = Provider<AdminReportRepository>(
  (ref) => AdminReportRepository(ref.watch(apiClientProvider)),
);
