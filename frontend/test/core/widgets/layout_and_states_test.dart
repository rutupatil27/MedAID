import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medaid/app/localization/locale_provider.dart';
import 'package:medaid/core/network/api_exception.dart';
import 'package:medaid/core/widgets/dialogs/confirmation_dialog.dart';
import 'package:medaid/core/widgets/empty_states/empty_state_view.dart';
import 'package:medaid/core/widgets/empty_states/error_view.dart';
import 'package:medaid/core/widgets/inputs/search_field.dart';
import 'package:medaid/core/widgets/layout/bottom_nav_bar.dart';
import 'package:medaid/core/widgets/layout/section_header.dart';
import 'package:medaid/core/widgets/loaders/async_value_view.dart';
import 'package:medaid/core/widgets/loaders/loading_view.dart';
import 'package:medaid/core/widgets/misc/language_selector.dart';
import 'package:medaid/core/widgets/misc/permission_prompt.dart';
import 'package:medaid/core/widgets/misc/profile_avatar.dart';

import '../../helpers/test_app.dart';

void main() {
  group('AsyncValueView', () {
    Widget view(AsyncValue<List<int>> value, {VoidCallback? onRetry}) => AsyncValueView<List<int>>(
      value: value,
      onRetry: onRetry,
      isEmpty: (items) => items.isEmpty,
      empty: const EmptyStateView(title: 'Nothing yet'),
      data: (items) => Text('count ${items.length}'),
    );

    testWidgets('loading', (tester) async {
      await pumpThemed(tester, view(const AsyncLoading()));
      expect(find.byType(LoadingView), findsOneWidget);
    });

    testWidgets('error with a localized message and retry', (tester) async {
      var retried = false;
      await pumpThemed(
        tester,
        view(
          const AsyncError(ApiException(code: ApiErrorCodes.network), StackTrace.empty),
          onRetry: () => retried = true,
        ),
      );

      expect(find.byType(ErrorView), findsOneWidget);
      expect(
        find.text('No internet connection. Check your network and try again.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);
    });

    testWidgets('empty and data', (tester) async {
      await pumpThemed(tester, view(const AsyncData([])));
      expect(find.text('Nothing yet'), findsOneWidget);

      await pumpThemed(tester, view(const AsyncData([1, 2])));
      expect(find.text('count 2'), findsOneWidget);
    });
  });

  testWidgets('ConfirmationDialog resolves true on confirm and false on cancel', (tester) async {
    bool? result;
    await pumpThemed(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showConfirmationDialog(
            context,
            title: 'Cancel alert?',
            message: 'Help will stop coming.',
            destructive: true,
          ),
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(result, isTrue);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('SearchField clears its text and notifies', (tester) async {
    final changes = <String>[];
    await pumpThemed(tester, SearchField(hint: 'Search', onChanged: changes.add));

    await tester.enterText(find.byType(TextField), 'camp');
    await tester.pump();
    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();

    expect(changes, ['camp', '']);
    expect(find.text('camp'), findsNothing);
  });

  testWidgets('BottomNavBar reports the selected index', (tester) async {
    int? selected;
    await pumpThemed(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: BottomNavBar(
          currentIndex: 0,
          onSelected: (i) => selected = i,
          items: const [
            NavItem(label: 'Home', icon: Icons.home_outlined, selectedIcon: Icons.home),
            NavItem(label: 'Profile', icon: Icons.person_outline, selectedIcon: Icons.person),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Profile'));
    expect(selected, 1);
  });

  testWidgets('SectionHeader action and EmptyStateView action are tappable', (tester) async {
    var actions = 0;
    await pumpThemed(
      tester,
      Column(
        children: [
          SectionHeader(title: 'Nearby', actionLabel: 'View all', onAction: () => actions++),
          EmptyStateView(title: 'Empty', actionLabel: 'Reload', onAction: () => actions++),
        ],
      ),
    );

    await tester.tap(find.text('View all'));
    await tester.tap(find.text('Reload'));
    expect(actions, 2);
  });

  testWidgets('PermissionPrompt offers grant and settings actions', (tester) async {
    var grants = 0;
    var settings = 0;
    await pumpThemed(
      tester,
      PermissionPrompt(
        title: 'Location needed',
        message: 'We use it to send help to you.',
        grantLabel: 'Allow',
        onGrant: () => grants++,
        settingsLabel: 'Open settings',
        onOpenSettings: () => settings++,
      ),
    );

    await tester.tap(find.text('Allow'));
    await tester.tap(find.text('Open settings'));
    expect((grants, settings), (1, 1));
  });

  test('ProfileAvatar initials handle one, many and Devanagari names', () {
    expect(ProfileAvatar.initialsOf('asha patil'), 'AP');
    expect(ProfileAvatar.initialsOf('Ravi'), 'R');
    expect(ProfileAvatar.initialsOf('   '), '?');
    expect(ProfileAvatar.initialsOf('आशा पाटील'), isNotEmpty);
  });

  testWidgets('LanguageSelector switches the app locale', (tester) async {
    await pumpThemed(tester, const LanguageSelector());
    final container = ProviderScope.containerOf(tester.element(find.byType(LanguageSelector)));

    await tester.tap(find.text('हिन्दी'));
    await tester.pumpAndSettle();

    expect(container.read(localeProvider), AppLocales.hindi);
  });
}
