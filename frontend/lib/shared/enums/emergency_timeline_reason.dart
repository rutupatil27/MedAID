import '../../app/localization/generated/app_localizations.dart';

/// Why an emergency moved to a status.
///
/// The assignment engine retries, so a timeline legitimately repeats
/// ASSIGNING and UNASSIGNED. Without the reason those rows are identical and
/// read as a bug, so each one says what happened.
///
/// The backend sends only these codes — never the free text a user or admin
/// typed — so there is nothing here to leak into someone else's timeline.
enum EmergencyTimelineReason {
  noLocation('NO_LOCATION'),
  noVolunteer('NO_ELIGIBLE_VOLUNTEER'),
  candidatesBusy('CANDIDATES_UNAVAILABLE'),
  volunteerUnavailable('VOLUNTEER_UNAVAILABLE'),
  timeout('TIMEOUT'),
  declined('DECLINED'),
  adminReassigned('ADMIN_REASSIGNED');

  const EmergencyTimelineReason(this.apiValue);

  final String apiValue;

  /// Unknown or absent codes give null rather than a wrong label: a new
  /// backend reason shows no explanation instead of the wrong one.
  static EmergencyTimelineReason? fromApi(Object? value) {
    for (final reason in values) {
      if (reason.apiValue == value) return reason;
    }
    return null;
  }

  String label(AppLocalizations l10n) => switch (this) {
    noLocation => l10n.emergencyReasonNoLocation,
    noVolunteer => l10n.emergencyReasonNoVolunteer,
    candidatesBusy => l10n.emergencyReasonCandidatesBusy,
    volunteerUnavailable => l10n.emergencyReasonVolunteerUnavailable,
    timeout => l10n.emergencyReasonTimeout,
    declined => l10n.emergencyReasonDeclined,
    adminReassigned => l10n.emergencyReasonAdminReassigned,
  };
}
