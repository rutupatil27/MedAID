import '../../app/localization/generated/app_localizations.dart';
import '../../core/theme/app_theme.dart';

enum VerificationStatus {
  notSubmitted('NOT_SUBMITTED'),
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED');

  const VerificationStatus(this.apiValue);

  final String apiValue;

  static VerificationStatus fromApi(Object? value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => VerificationStatus.notSubmitted);

  String label(AppLocalizations l10n) => switch (this) {
    notSubmitted => l10n.verificationNotSubmitted,
    pending => l10n.verificationPending,
    approved => l10n.verificationApproved,
    rejected => l10n.verificationRejected,
  };

  AppTone get tone => switch (this) {
    notSubmitted => AppTone.neutral,
    pending => AppTone.warning,
    approved => AppTone.success,
    rejected => AppTone.danger,
  };
}

enum VolunteerStatus {
  offline('OFFLINE'),
  active('ACTIVE'),
  busy('BUSY');

  const VolunteerStatus(this.apiValue);

  final String apiValue;

  static VolunteerStatus fromApi(Object? value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => VolunteerStatus.offline);

  String label(AppLocalizations l10n) => switch (this) {
    offline => l10n.volunteerStatusOffline,
    active => l10n.volunteerStatusActive,
    busy => l10n.volunteerStatusBusy,
  };

  AppTone get tone => switch (this) {
    offline => AppTone.neutral,
    active => AppTone.success,
    busy => AppTone.info,
  };
}

enum DocumentType {
  idProof('ID_PROOF'),
  firstAidCertificate('FIRST_AID_CERTIFICATE'),
  other('OTHER');

  const DocumentType(this.apiValue);

  final String apiValue;

  static DocumentType fromApi(Object? value) =>
      values.firstWhere((t) => t.apiValue == value, orElse: () => DocumentType.other);

  String label(AppLocalizations l10n) => switch (this) {
    idProof => l10n.documentTypeIdProof,
    firstAidCertificate => l10n.documentTypeFirstAid,
    other => l10n.documentTypeOther,
  };
}

enum DocumentStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED'),
  replaced('REPLACED');

  const DocumentStatus(this.apiValue);

  final String apiValue;

  static DocumentStatus fromApi(Object? value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => DocumentStatus.pending);

  String label(AppLocalizations l10n) => switch (this) {
    pending || replaced => l10n.documentStatusPending,
    approved => l10n.documentStatusApproved,
    rejected => l10n.documentStatusRejected,
  };
}

enum AssignmentStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  declined('DECLINED'),
  expired('EXPIRED'),
  cancelled('CANCELLED'),
  completed('COMPLETED');

  const AssignmentStatus(this.apiValue);

  final String apiValue;

  static AssignmentStatus fromApi(Object? value) =>
      values.firstWhere((s) => s.apiValue == value, orElse: () => AssignmentStatus.pending);

  bool get isActive => this == pending || this == accepted;

  String label(AppLocalizations l10n) => switch (this) {
    pending => l10n.assignmentPending,
    accepted => l10n.assignmentAccepted,
    declined => l10n.assignmentDeclined,
    expired => l10n.assignmentExpired,
    cancelled => l10n.assignmentCancelled,
    completed => l10n.assignmentCompleted,
  };

  AppTone get tone => switch (this) {
    pending => AppTone.warning,
    accepted => AppTone.info,
    completed => AppTone.success,
    declined || expired || cancelled => AppTone.neutral,
  };
}
