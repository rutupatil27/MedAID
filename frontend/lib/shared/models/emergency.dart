import '../../core/utils/json.dart';
import '../enums/emergency_status.dart';
import '../enums/emergency_timeline_reason.dart';
import '../enums/volunteer_enums.dart';
import 'app_user.dart';
import 'geo_point.dart';

class EmergencyTimelineEntry {
  const EmergencyTimelineEntry({required this.status, this.at, this.reason});

  factory EmergencyTimelineEntry.fromJson(JsonMap json) => EmergencyTimelineEntry(
    status: EmergencyStatus.fromApi(json['status']),
    // Never invented: showing "now" for an entry whose time did not arrive
    // would present a guess as history.
    at: asDateTime(json['at']),
    reason: EmergencyTimelineReason.fromApi(json['reason']),
  );

  final EmergencyStatus status;
  final DateTime? at;

  /// Why this happened, when the backend knows. An emergency retries
  /// assignment, so the same status repeats; the reason is what tells the
  /// repeats apart.
  final EmergencyTimelineReason? reason;
}

/// The volunteer who accepted the alert, as shown to the reporting User.
class EmergencyResponder {
  const EmergencyResponder({this.name, this.estimatedDurationSeconds, this.routeDistanceMeters});

  factory EmergencyResponder.fromJson(JsonMap json) => EmergencyResponder(
    name: asString(json['name']),
    estimatedDurationSeconds: asDouble(json['estimatedDurationSeconds']),
    routeDistanceMeters: asDouble(json['routeDistanceMeters']),
  );

  final String? name;
  final double? estimatedDurationSeconds;
  final double? routeDistanceMeters;
}

/// Short volunteer identity shown on admin emergency views.
class VolunteerSummary {
  const VolunteerSummary({required this.id, this.name, this.phone, this.status});

  factory VolunteerSummary.fromJson(JsonMap json) => VolunteerSummary(
    id: asStringOr(json['id'], ''),
    name: asString(json['name']),
    phone: asString(json['phone']),
    status: json['status'] == null ? null : VolunteerStatus.fromApi(json['status']),
  );

  final String id;
  final String? name;
  final String? phone;
  final VolunteerStatus? status;
}

/// One dispatch attempt, as seen by the volunteer and admins.
class EmergencyAssignmentInfo {
  const EmergencyAssignmentInfo({
    required this.id,
    required this.status,
    required this.attemptNumber,
    required this.dispatchedAt,
    required this.expiresAt,
    this.volunteerId,
    this.acceptedAt,
    this.endedAt,
    this.endReason,
    this.routeDistanceMeters,
    this.estimatedDurationSeconds,
    this.distanceSource,
    this.volunteer,
  });

  factory EmergencyAssignmentInfo.fromJson(JsonMap json) => EmergencyAssignmentInfo(
    volunteer: json['volunteer'] is Map<String, dynamic>
        ? VolunteerSummary.fromJson(json['volunteer'] as JsonMap)
        : null,
    id: asStringOr(json['id'], ''),
    volunteerId: asString(json['volunteerId']),
    status: AssignmentStatus.fromApi(json['status']),
    attemptNumber: asInt(json['attemptNumber']) ?? 1,
    dispatchedAt: asDateTime(json['dispatchedAt']) ?? DateTime.now(),
    expiresAt: asDateTime(json['expiresAt']) ?? DateTime.now(),
    acceptedAt: asDateTime(json['acceptedAt']),
    endedAt:
        asDateTime(json['completedAt']) ??
        asDateTime(json['expiredAt']) ??
        asDateTime(json['declinedAt']) ??
        asDateTime(json['cancelledAt']),
    endReason: asString(json['endReason']),
    routeDistanceMeters: asDouble(json['routeDistanceMeters']),
    estimatedDurationSeconds: asDouble(json['estimatedDurationSeconds']),
    distanceSource: asString(json['distanceSource']),
  );

  final String id;
  final String? volunteerId;
  final AssignmentStatus status;
  final int attemptNumber;
  final DateTime dispatchedAt;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final DateTime? endedAt;
  final String? endReason;
  final double? routeDistanceMeters;
  final double? estimatedDurationSeconds;
  final String? distanceSource;

  /// Admin views only.
  final VolunteerSummary? volunteer;
}

/// The person who raised the alert, as shared with the responding volunteer.
class EmergencyReporter {
  const EmergencyReporter({required this.name, this.phone, this.medicalProfile});

  factory EmergencyReporter.fromJson(JsonMap json) {
    final medical = json['medicalProfile'];
    return EmergencyReporter(
      name: asStringOr(json['name'], ''),
      phone: asString(json['phone']),
      medicalProfile: medical is Map<String, dynamic> ? MedicalProfile.fromJson(medical) : null,
    );
  }

  final String name;
  final String? phone;

  /// Present only with the reporter's consent, while responding.
  final MedicalProfile? medicalProfile;
}

/// Emergency alert fields shared by every role's view.
class Emergency {
  const Emergency({
    required this.id,
    required this.alertNumber,
    required this.status,
    required this.createdAt,
    this.location,
    this.locationAccuracy,
    this.message,
    this.assignedAt,
    this.acceptedAt,
    this.startedAt,
    this.resolvedAt,
    this.cancelledAt,
    this.timeline = const [],
    this.responder,
    this.resolutionNote,
    this.assignment,
    this.reporter,
    this.attemptCount = 0,
    this.assignedVolunteer,
    this.assignments = const [],
  });

  factory Emergency.fromJson(JsonMap json) {
    final responder = json['responder'];
    final assignment = json['assignment'];
    final reporter = json['reporter'];
    return Emergency(
      id: asStringOr(json['id'], ''),
      alertNumber: asStringOr(json['alertNumber'], ''),
      status: EmergencyStatus.fromApi(json['status']),
      createdAt: asDateTime(json['createdAt']) ?? DateTime.now(),
      location: GeoPoint.tryFromJson(json['location']),
      locationAccuracy: asDouble(json['locationAccuracy']),
      message: asString(json['message']),
      assignedAt: asDateTime(json['assignedAt']),
      acceptedAt: asDateTime(json['acceptedAt']),
      startedAt: asDateTime(json['startedAt']),
      resolvedAt: asDateTime(json['resolvedAt']),
      cancelledAt: asDateTime(json['cancelledAt']),
      timeline: asJsonList(json['timeline']).map(EmergencyTimelineEntry.fromJson).toList(),
      responder: responder is Map<String, dynamic> ? EmergencyResponder.fromJson(responder) : null,
      resolutionNote: asString(json['resolutionNote']),
      assignment: assignment is Map<String, dynamic>
          ? EmergencyAssignmentInfo.fromJson(assignment)
          : null,
      reporter: reporter is Map<String, dynamic> ? EmergencyReporter.fromJson(reporter) : null,
      attemptCount: asInt(json['attemptCount']) ?? 0,
      assignedVolunteer: json['assignedVolunteer'] is Map<String, dynamic>
          ? VolunteerSummary.fromJson(json['assignedVolunteer'] as JsonMap)
          : null,
      assignments: asJsonList(json['assignments']).map(EmergencyAssignmentInfo.fromJson).toList(),
    );
  }

  final String id;
  final String alertNumber;
  final EmergencyStatus status;
  final DateTime createdAt;
  final GeoPoint? location;
  final double? locationAccuracy;
  final String? message;
  final DateTime? assignedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? resolvedAt;
  final DateTime? cancelledAt;
  final List<EmergencyTimelineEntry> timeline;
  final EmergencyResponder? responder;
  final String? resolutionNote;

  /// The viewing volunteer's assignment (volunteer views).
  final EmergencyAssignmentInfo? assignment;
  final EmergencyReporter? reporter;

  /// Admin views only.
  final int attemptCount;
  final VolunteerSummary? assignedVolunteer;
  final List<EmergencyAssignmentInfo> assignments;

  bool get isOpen => status.isOpen;
}
