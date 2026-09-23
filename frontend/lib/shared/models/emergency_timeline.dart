import '../../app/localization/generated/app_localizations.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/misc/status_timeline.dart';
import 'emergency.dart';

/// Turns an emergency's history into rows for [StatusTimeline].
///
/// Shared by the User, Volunteer and Admin detail screens so all three read
/// the same, and because getting this right takes more care than it looks:
///
/// - The engine retries, so the same status appears several times. Each row
///   carries its reason, which is the only thing telling the repeats apart.
/// - Those repeats can be under a second apart, and hour:minute renders them
///   as identical times. Seconds appear only when two entries share a minute.
/// - Times are shown without a date, which is unreadable once an emergency
///   runs past midnight, so the date appears on the first row and again
///   whenever the day changes.
List<TimelineItem> emergencyTimelineItems(
  List<EmergencyTimelineEntry> timeline,
  AppLocalizations l10n,
  AppFormatters format,
) {
  final withSeconds = _anyShareAMinute(timeline);
  final items = <TimelineItem>[];
  DateTime? previous;

  for (final entry in timeline) {
    final at = entry.at;
    items.add(
      TimelineItem(
        label: entry.status.label(l10n),
        time: at == null
            ? _unknownTime
            : _formatted(
                at,
                format,
                withDate: previous == null || !_sameDay(previous, at),
                withSeconds: withSeconds,
              ),
        detail: entry.reason?.label(l10n),
        tone: entry.status.tone,
      ),
    );
    if (at != null) previous = at;
  }
  return items;
}

/// Shown when an entry arrived without a time. Nothing is guessed: a made-up
/// timestamp in a history is worse than an admitted gap.
const _unknownTime = '—';

String _formatted(
  DateTime at,
  AppFormatters format, {
  required bool withDate,
  required bool withSeconds,
}) {
  if (withDate) {
    return withSeconds ? format.shortDateTimeWithSeconds(at) : format.shortDateTime(at);
  }
  return withSeconds ? format.timeWithSeconds(at) : format.time(at);
}

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

bool _anyShareAMinute(List<EmergencyTimelineEntry> timeline) {
  final minutes = <int>{};
  for (final entry in timeline) {
    final at = entry.at;
    if (at == null) continue;
    if (!minutes.add(
      DateTime(at.year, at.month, at.day, at.hour, at.minute).microsecondsSinceEpoch,
    )) {
      return true;
    }
  }
  return false;
}
