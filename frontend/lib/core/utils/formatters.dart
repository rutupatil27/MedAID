import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../app/localization/generated/app_localizations.dart';

/// Locale-aware formatting for distances, times and ETAs (doc 17).
class AppFormatters {
  AppFormatters(this._l10n, Locale locale) : _locale = locale.toLanguageTag();

  factory AppFormatters.of(BuildContext context) =>
      AppFormatters(AppLocalizations.of(context), Localizations.localeOf(context));

  final AppLocalizations _l10n;
  final String _locale;

  String distance(num? meters) {
    if (meters == null) return '';
    if (meters < 1000) {
      final rounded = (meters / 10).round() * 10;
      return _l10n.distanceMeters(NumberFormat.decimalPattern(_locale).format(rounded));
    }
    return _l10n.distanceKilometers(NumberFormat('0.0', _locale).format(meters / 1000));
  }

  String relativeTime(DateTime time, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);
    if (diff.inMinutes < 1) return _l10n.timeJustNow;
    if (diff.inMinutes < 60) return _l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return _l10n.timeHoursAgo(diff.inHours);
    return dateTime(time);
  }

  String dateTime(DateTime time) => DateFormat.yMMMd(_locale).add_jm().format(time);

  String shortDateTime(DateTime time) => DateFormat.MMMd(_locale).add_jm().format(time);

  String time(DateTime time) => DateFormat.jm(_locale).format(time);

  /// For sequences where entries can share a minute — an emergency can change
  /// status three times in one second, and identical times read as duplicates.
  String timeWithSeconds(DateTime time) => DateFormat.jms(_locale).format(time);

  String shortDateTimeWithSeconds(DateTime time) => DateFormat.MMMd(_locale).add_jms().format(time);

  String date(DateTime time) => DateFormat.yMMMd(_locale).format(time);

  /// e.g. "17 Sept 2026, 8:00 AM – 18 Sept 2026, 8:00 PM".
  String dateTimeRange(DateTime start, DateTime end) => '${dateTime(start)} – ${dateTime(end)}';

  /// "Label: value", with a dash for missing values.
  static String labelled(String label, String? value) =>
      '$label: ${value == null || value.isEmpty ? '—' : value}';

  /// Whole minutes, rounded up, never below one.
  static int etaMinutes(num seconds) => (seconds / 60).ceil().clamp(1, 24 * 60).toInt();
}
