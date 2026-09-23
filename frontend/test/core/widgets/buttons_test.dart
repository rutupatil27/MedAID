import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medaid/core/theme/app_theme.dart';
import 'package:medaid/core/widgets/buttons/danger_button.dart';
import 'package:medaid/core/widgets/buttons/emergency_button.dart';
import 'package:medaid/core/widgets/buttons/primary_button.dart';
import 'package:medaid/core/widgets/buttons/secondary_button.dart';

import '../../helpers/test_app.dart';

void main() {
  group('PrimaryButton', () {
    testWidgets('fires onPressed', (tester) async {
      var taps = 0;
      await pumpThemed(tester, PrimaryButton(label: 'Go', onPressed: () => taps++));

      await tester.tap(find.text('Go'));
      expect(taps, 1);
    });

    testWidgets('blocks taps and shows a spinner while loading', (tester) async {
      var taps = 0;
      await pumpThemed(
        tester,
        PrimaryButton(label: 'Go', isLoading: true, onPressed: () => taps++),
      );

      await tester.tap(find.byType(FilledButton));
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Go'), findsNothing);
    });
  });

  testWidgets('SecondaryButton renders its label and icon', (tester) async {
    await pumpThemed(
      tester,
      SecondaryButton(label: 'Later', icon: Icons.schedule, onPressed: () {}),
    );

    expect(find.text('Later'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
  });

  testWidgets('DangerButton uses the emergency colour token', (tester) async {
    await pumpThemed(tester, DangerButton(label: 'Send', onPressed: () {}));

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final color = button.style?.backgroundColor?.resolve(<WidgetState>{});
    expect(color, AppColors.emergency);
  });

  group('EmergencyButton (SOS)', () {
    Widget sos(VoidCallback onActivated, {bool enabled = true}) => Center(
      child: EmergencyButton(
        label: 'SOS',
        hint: 'Hold for help',
        semanticLabel: 'Send emergency alert',
        enabled: enabled,
        onActivated: onActivated,
      ),
    );

    testWidgets('activates only after being held for the full duration', (tester) async {
      var activations = 0;
      await pumpThemed(tester, sos(() => activations++));

      final gesture = await tester.startGesture(tester.getCenter(find.text('SOS')));
      await tester.pump(AppDurations.sosHold ~/ 2);
      expect(activations, 0);

      await tester.pump(AppDurations.sosHold);
      await tester.pump(const Duration(milliseconds: 16)); // next frame completes the hold
      expect(activations, 1);
      await gesture.up();
    });

    testWidgets('releasing early cancels the alert', (tester) async {
      var activations = 0;
      await pumpThemed(tester, sos(() => activations++));

      final gesture = await tester.startGesture(tester.getCenter(find.text('SOS')));
      await tester.pump(AppDurations.sosHold ~/ 3);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(activations, 0);
    });

    testWidgets('screen-reader tap activates immediately', (tester) async {
      final handle = tester.ensureSemantics();
      var activations = 0;
      await pumpThemed(tester, sos(() => activations++));

      tester.semantics.tap(find.semantics.byLabel('Send emergency alert'));
      await tester.pump();

      expect(activations, 1);
      handle.dispose();
    });

    testWidgets('does nothing when disabled', (tester) async {
      var activations = 0;
      await pumpThemed(tester, sos(() => activations++, enabled: false));

      final gesture = await tester.startGesture(tester.getCenter(find.text('SOS')));
      await tester.pump(AppDurations.sosHold * 2);
      await gesture.up();

      expect(activations, 0);
    });
  });
}
