import '../../app/localization/generated/app_localizations.dart';

typedef FieldValidator = String? Function(String? value);

/// Localized form validators mirroring backend rules, so users see problems
/// before a request is sent.
class FormValidators {
  const FormValidators(this._l10n);

  final AppLocalizations _l10n;

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final _username = RegExp(r'^[a-zA-Z0-9_.]{3,30}$');
  static final _phone = RegExp(r'^\+?[0-9][0-9\s-]{6,18}$');
  static final _letter = RegExp('[A-Za-z]');
  static final _digit = RegExp(r'\d');

  static bool _isBlank(String? v) => v == null || v.trim().isEmpty;

  String? required(String? value) => _isBlank(value) ? _l10n.validationRequired : null;

  String? name(String? value) {
    if (_isBlank(value)) return _l10n.validationRequired;
    return value!.trim().length < 2 ? _l10n.validationName : null;
  }

  String? email(String? value) {
    if (_isBlank(value)) return _l10n.validationRequired;
    return _email.hasMatch(value!.trim()) ? null : _l10n.validationEmail;
  }

  String? username(String? value) {
    if (_isBlank(value)) return _l10n.validationRequired;
    return _username.hasMatch(value!.trim()) ? null : _l10n.validationUsername;
  }

  String? password(String? value) {
    if (_isBlank(value)) return _l10n.validationRequired;
    final v = value!;
    final ok = v.length >= 8 && v.length <= 128 && _letter.hasMatch(v) && _digit.hasMatch(v);
    return ok ? null : _l10n.validationPassword;
  }

  String? optionalPhone(String? value) {
    if (_isBlank(value)) return null;
    return _phone.hasMatch(value!.trim()) ? null : _l10n.validationPhone;
  }

  FieldValidator matches(String Function() other) =>
      (value) => value == other() ? null : _l10n.validationPasswordMismatch;

  FieldValidator newPassword(String Function() current) => (value) {
    final error = password(value);
    if (error != null) return error;
    return value == current() ? _l10n.validationPasswordSame : null;
  };
}
