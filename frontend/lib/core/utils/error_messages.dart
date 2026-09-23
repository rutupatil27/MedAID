import '../../app/localization/generated/app_localizations.dart';
import '../network/api_exception.dart';

/// Maps any error to a localized, user-safe message. Raw server messages are
/// never shown (doc 17: backend codes stay language-neutral).
String localizedErrorMessage(AppLocalizations l10n, Object? error) {
  if (error is! ApiException) return l10n.errorGeneric;
  return switch (error.code) {
    ApiErrorCodes.network => l10n.errorNetwork,
    ApiErrorCodes.timeout => l10n.errorTimeout,
    ApiErrorCodes.authInvalid => l10n.errorAuthInvalid,
    ApiErrorCodes.authUnauthorized => l10n.errorUnauthorized,
    ApiErrorCodes.forbidden => l10n.errorForbidden,
    ApiErrorCodes.accountSuspended => l10n.errorAccountSuspended,
    ApiErrorCodes.passwordChangeRequired => l10n.errorPasswordChangeRequired,
    ApiErrorCodes.validation => l10n.errorValidation,
    ApiErrorCodes.notFound => l10n.errorNotFound,
    ApiErrorCodes.conflict => l10n.errorConflict,
    ApiErrorCodes.rateLimited => l10n.errorRateLimited,
    ApiErrorCodes.volunteerNotVerified => l10n.errorVolunteerNotVerified,
    ApiErrorCodes.volunteerNotAvailable => l10n.errorVolunteerNotAvailable,
    ApiErrorCodes.emergencyAlreadyAssigned => l10n.errorEmergencyAlreadyAssigned,
    ApiErrorCodes.assignmentExpired => l10n.errorAssignmentExpired,
    ApiErrorCodes.locationUnavailable => l10n.errorLocationUnavailable,
    ApiErrorCodes.routingUnavailable => l10n.errorRoutingUnavailable,
    ApiErrorCodes.fileUploadFailed => l10n.errorFileUploadFailed,
    ApiErrorCodes.fileTooLarge => l10n.errorFileTooLarge,
    ApiErrorCodes.internal => l10n.errorInternal,
    _ => l10n.errorGeneric,
  };
}
