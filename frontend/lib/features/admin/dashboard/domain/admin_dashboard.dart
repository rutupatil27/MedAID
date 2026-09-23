import '../../../../core/utils/json.dart';
import '../../../../shared/models/emergency.dart';

class AdminDashboard {
  const AdminDashboard({
    required this.openEmergencies,
    required this.unassigned,
    required this.awaitingAcceptance,
    required this.inProgress,
    required this.today,
    required this.pendingVerification,
    required this.activeVolunteers,
    required this.busyVolunteers,
    required this.activeCamps,
    required this.recentOpen,
  });

  factory AdminDashboard.fromJson(JsonMap json) {
    final emergencies = asJsonMap(json['emergencies']);
    final volunteers = asJsonMap(json['volunteers']);
    final byStatus = asJsonMap(volunteers['byStatus']);
    return AdminDashboard(
      openEmergencies: asInt(emergencies['open']) ?? 0,
      unassigned: asInt(emergencies['unassigned']) ?? 0,
      awaitingAcceptance: asInt(emergencies['awaitingAcceptance']) ?? 0,
      inProgress: asInt(emergencies['inProgress']) ?? 0,
      today: asInt(emergencies['today']) ?? 0,
      pendingVerification: asInt(volunteers['pendingVerification']) ?? 0,
      activeVolunteers: asInt(byStatus['ACTIVE']) ?? 0,
      busyVolunteers: asInt(byStatus['BUSY']) ?? 0,
      activeCamps: asInt(asJsonMap(json['camps'])['activeNow']) ?? 0,
      recentOpen: asJsonList(json['recentOpenEmergencies']).map(Emergency.fromJson).toList(),
    );
  }

  final int openEmergencies;
  final int unassigned;
  final int awaitingAcceptance;
  final int inProgress;
  final int today;
  final int pendingVerification;
  final int activeVolunteers;
  final int busyVolunteers;
  final int activeCamps;
  final List<Emergency> recentOpen;
}
