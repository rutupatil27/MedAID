import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medaid/core/theme/app_theme.dart';
import 'package:medaid/core/widgets/cards/document_upload_tile.dart';
import 'package:medaid/core/widgets/cards/emergency_card.dart';
import 'package:medaid/core/widgets/cards/facility_card.dart';
import 'package:medaid/core/widgets/cards/medical_camp_card.dart';
import 'package:medaid/core/widgets/cards/stat_card.dart';
import 'package:medaid/core/widgets/cards/volunteer_status_card.dart';
import 'package:medaid/core/widgets/chips/status_chip.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('StatusChip colours come from the tone palette', (tester) async {
    await pumpThemed(tester, const StatusChip(label: 'Active', tone: AppTone.success));

    final text = tester.widget<Text>(find.text('Active'));
    expect(text.style?.color, AppColors.success);
  });

  testWidgets('FacilityCard shows up to three services and a remainder count', (tester) async {
    var tapped = false;
    await pumpThemed(
      tester,
      FacilityCard(
        name: 'City Hospital',
        typeLabel: 'Hospital',
        distanceLabel: '1.2 km',
        services: const ['ER', 'ICU', 'X-ray', 'Lab', 'Pharmacy'],
        onTap: () => tapped = true,
      ),
    );

    expect(find.text('ER'), findsOneWidget);
    expect(find.text('X-ray'), findsOneWidget);
    expect(find.text('Lab'), findsNothing);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('1.2 km'), findsOneWidget);

    await tester.tap(find.text('City Hospital'));
    expect(tapped, isTrue);
  });

  testWidgets('MedicalCampCard shows its validity period', (tester) async {
    await pumpThemed(
      tester,
      const MedicalCampCard(
        name: 'Ghat Camp 4',
        typeLabel: 'Medical camp',
        validityLabel: 'Open until 8:00 PM',
      ),
    );

    expect(find.text('Open until 8:00 PM'), findsOneWidget);
    expect(find.byIcon(Icons.medical_services_rounded), findsOneWidget);
  });

  testWidgets('EmergencyCard renders status and details', (tester) async {
    await pumpThemed(
      tester,
      const EmergencyCard(
        title: 'MED-20260917-0001',
        statusLabel: 'Assigned',
        statusTone: AppTone.info,
        timeLabel: '2 min ago',
        highlight: true,
        details: [(icon: Icons.near_me_rounded, text: '350 m')],
      ),
    );

    expect(find.text('MED-20260917-0001'), findsOneWidget);
    expect(find.text('Assigned'), findsOneWidget);
    expect(find.text('350 m'), findsOneWidget);
  });

  testWidgets('VolunteerStatusCard reports switch changes', (tester) async {
    bool? changed;
    await pumpThemed(
      tester,
      VolunteerStatusCard(
        title: 'Availability',
        statusLabel: 'Offline',
        statusTone: AppTone.neutral,
        switchValue: false,
        onSwitchChanged: (v) => changed = v,
      ),
    );

    await tester.tap(find.byType(Switch));
    expect(changed, isTrue);
  });

  testWidgets('DocumentUploadTile shows progress while uploading and hides the action', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      DocumentUploadTile(
        title: 'ID proof',
        state: DocumentTileState.uploading,
        actionLabel: 'Upload',
        progress: 0.4,
        onAction: () {},
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Upload'), findsNothing);
  });

  testWidgets('DocumentUploadTile shows a rejection note and replace action', (tester) async {
    var picked = false;
    await pumpThemed(
      tester,
      DocumentUploadTile(
        title: 'ID proof',
        state: DocumentTileState.rejected,
        statusLabel: 'Rejected',
        note: 'Photo is blurry',
        actionLabel: 'Replace',
        onAction: () => picked = true,
      ),
    );

    expect(find.text('Photo is blurry'), findsOneWidget);
    await tester.tap(find.text('Replace'));
    expect(picked, isTrue);
  });

  testWidgets('StatCard shows value and label', (tester) async {
    await pumpThemed(
      tester,
      const StatCard(label: 'Active alerts', value: '12', icon: Icons.emergency),
    );

    expect(find.text('12'), findsOneWidget);
    expect(find.text('Active alerts'), findsOneWidget);
  });
}
