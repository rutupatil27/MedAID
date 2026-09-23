/// Language-neutral error codes shared with the backend (doc 23).
/// Flutter maps these to localized messages; it never shows raw server text.
abstract final class ApiErrorCodes {
  static const authInvalid = 'AUTH_INVALID';
  static const authUnauthorized = 'AUTH_UNAUTHORIZED';
  static const forbidden = 'FORBIDDEN';
  static const accountSuspended = 'ACCOUNT_SUSPENDED';
  static const passwordChangeRequired = 'PASSWORD_CHANGE_REQUIRED';
  static const validation = 'VALIDATION_ERROR';
  static const notFound = 'NOT_FOUND';
  static const conflict = 'CONFLICT';
  static const rateLimited = 'RATE_LIMITED';
  static const volunteerNotVerified = 'VOLUNTEER_NOT_VERIFIED';
  static const volunteerNotAvailable = 'VOLUNTEER_NOT_AVAILABLE';
  static const emergencyAlreadyAssigned = 'EMERGENCY_ALREADY_ASSIGNED';
  static const assignmentExpired = 'ASSIGNMENT_EXPIRED';
  static const locationUnavailable = 'LOCATION_UNAVAILABLE';
  static const routingUnavailable = 'ROUTING_UNAVAILABLE';
  static const fileUploadFailed = 'FILE_UPLOAD_FAILED';
  static const internal = 'INTERNAL_ERROR';

  // Client-side only
  static const network = 'NETWORK_ERROR';
  static const timeout = 'TIMEOUT';
  static const fileTooLarge = 'FILE_TOO_LARGE';
  static const unknown = 'UNKNOWN';
}

class FieldError {
  const FieldError({required this.field, required this.message});

  factory FieldError.fromJson(Map<String, dynamic> json) => FieldError(
    field: json['field']?.toString() ?? '',
    message: json['message']?.toString() ?? '',
  );

  final String field;
  final String message;
}

class ApiException implements Exception {
  const ApiException({required this.code, this.message, this.statusCode, this.errors = const []});

  final String code;

  /// Server message, for logs/debugging only. Do not show it to users.
  final String? message;
  final int? statusCode;
  final List<FieldError> errors;

  bool get isUnauthorized => code == ApiErrorCodes.authUnauthorized;
  bool get isNetwork => code == ApiErrorCodes.network || code == ApiErrorCodes.timeout;

  @override
  String toString() => 'ApiException($code, status: $statusCode, message: $message)';
}
