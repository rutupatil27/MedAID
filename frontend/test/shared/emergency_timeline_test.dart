import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:medaid/app/localization/generated/app_localizations.dart';
import 'package:medaid/core/utils/formatters.dart';
import 'package:medaid/shared/enums/emergency_status.dart';
import 'package:medaid/shared/enums/emergency_timeline_reason.dart';
import 'package:medaid/shared/models/emergency.dart';
import 'package:medaid/shared/models/emergency_timeline.dart';

void main() {
  const locale = Locale('en');
  final l10n = lookupAppLocalizations(locale);
  final format = AppFormatters(l10n, locale);

  // The app gets this from Flutter's localization delegates; a plain unit
  // test has to ask for it.
  setUpAll(() => initializeDateFormatting(locale.toLanguageTag()));

  List<TimelineEntryView> build(List<EmergencyTimelineEntry> timeline) =>
      emergencyTimelineItems(timeline, l10n, format)
          // ICU separates the AM/PM marker with a narrow no-break space, which
          // is not what a test should be pinning down.
          .map(
            (item) => (
              label: item.label,
              time: item.time.replaceAll(RegExp(r'\s+'), ' '),
              detail: item.detail,
            ),
          )
          .toList();

  EmergencyTimelineEntry entry(
    EmergencyStatus status,
    DateTime? at, {
    EmergencyTimelineReason? reason,
  }) => EmergencyTimelineEntry(status: status, at: at, reason: reason);

  test('repeated statuses are told apart by why they happened', () {
    final items = build([
      entry(EmergencyStatus.created, DateTime(2026, 9, 23, 0, 9, 8)),
      entry(
        EmergencyStatus.unassigned,
        DateTime(2026, 9, 23, 0, 10),
        reason: EmergencyTimelineReason.noVolunteer,
      ),
      entry(
        EmergencyStatus.unassigned,
        DateTime(2026, 9, 23, 0, 41),
        reason: EmergencyTimelineReason.candidatesBusy,
      ),
    ]);

    // Same label twice, but the reader can see they are different events.
    expect(items[1].label, items[2].label);
    expect(items[1].detail, 'No volunteer available nearby');
    expect(items[2].detail, 'Nearby volunteers were busy');
  });

  test('shows seconds when two entries fall in the same minute', () {
    // A real emergency passed through three statuses in 0.6 seconds; at
    // minute precision all three printed the same time and looked duplicated.
    final items = build([
      entry(EmergencyStatus.created, DateTime(2026, 9, 23, 0, 9, 8)),
      entry(EmergencyStatus.assigning, DateTime(2026, 9, 23, 0, 9, 8)),
      entry(EmergencyStatus.unassigned, DateTime(2026, 9, 23, 0, 9, 54)),
    ]);

    expect(items[1].time, '12:09:08 AM');
    expect(items[2].time, '12:09:54 AM');
  });

  test('leaves seconds off when every entry has its own minute', () {
    final items = build([
      entry(EmergencyStatus.created, DateTime(2026, 9, 23, 0, 9)),
      entry(EmergencyStatus.accepted, DateTime(2026, 9, 23, 0, 42)),
    ]);

    expect(items[1].time, '12:42 AM');
  });

  test('dates the first entry, so a time alone is never ambiguous', () {
    final items = build([entry(EmergencyStatus.created, DateTime(2026, 9, 23, 0, 9))]);

    expect(items.single.time, 'Sep 23 12:09 AM');
  });

  test('dates an entry again once the emergency runs into the next day', () {
    final items = build([
      entry(EmergencyStatus.created, DateTime(2026, 9, 23, 23, 50)),
      entry(EmergencyStatus.assigning, DateTime(2026, 9, 23, 23, 55)),
      entry(EmergencyStatus.accepted, DateTime(2026, 9, 24, 0, 5)),
    ]);

    expect(items[0].time, 'Sep 23 11:50 PM');
    expect(items[1].time, '11:55 PM', reason: 'same day needs no date');
    expect(items[2].time, 'Sep 24 12:05 AM');
  });

  test('admits a missing time rather than inventing one', () {
    final items = build([entry(EmergencyStatus.created, null)]);

    expect(items.single.time, '—');
  });

  test('says nothing when the backend sends a reason the app does not know', () {
    final parsed = EmergencyTimelineEntry.fromJson(const {
      'status': 'UNASSIGNED',
      'at': '2026-09-23T00:09:00.000Z',
      'reason': 'SOME_FUTURE_REASON',
    });

    expect(parsed.reason, isNull);
    expect(build([parsed]).single.detail, isNull);
  });
}

typedef TimelineEntryView = ({String label, String time, String? detail});
