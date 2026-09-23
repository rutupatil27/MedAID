import '../../app/localization/generated/app_localizations.dart';
import '../../core/theme/app_theme.dart';

enum EmergencyStatus {
  created('CREATED'),
  assigning('ASSIGNING'),
  assigned('ASSIGNED'),
  accepted('ACCEPTED'),
  inProgress('IN_PROGRESS'),
  resolved('RESOLVED'),
  cancelled('CANCELLED'),
  expired('EXPIRED'),
  unassigned('UNASSIGNED');

  const EmergencyStatus(this.apiValue);

  final String apiValue;

  static EmergencyStatus fromApi(Object? value) => EmergencyStatus.values.firstWhere(
    (s) => s.apiValue == value,
    orElse: () => EmergencyStatus.created,
  );

  bool get isOpen => !isTerminal;

  bool get isTerminal => this == resolved || this == cancelled || this == expired;

  /// Help has actually been accepted by a volunteer.
  bool get isHelpComing => this == accepted || this == inProgress;

  String label(AppLocalizations l10n) => switch (this) {
    created => l10n.emergencyStatusCreated,
    assigning => l10n.emergencyStatusAssigning,
    assigned => l10n.emergencyStatusAssigned,
    accepted => l10n.emergencyStatusAccepted,
    inProgress => l10n.emergencyStatusInProgress,
    resolved => l10n.emergencyStatusResolved,
    cancelled => l10n.emergencyStatusCancelled,
    expired => l10n.emergencyStatusExpired,
    unassigned => l10n.emergencyStatusUnassigned,
  };

  AppTone get tone => switch (this) {
    created || assigning || assigned => AppTone.warning,
    accepted || inProgress => AppTone.info,
    resolved => AppTone.success,
    cancelled || expired => AppTone.neutral,
    unassigned => AppTone.emergency,
  };
}
