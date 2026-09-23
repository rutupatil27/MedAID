import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../dialogs/confirmation_dialog.dart';

class NavItem {
  const NavItem({required this.label, required this.icon, required this.selectedIcon});

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Minimal bottom navigation used by every role shell.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.palette.border)),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onSelected,
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}

/// Scaffold for a role's [StatefulShellRoute]: keeps each tab's state alive.
///
/// Handles the system back gesture or button: from any other tab it returns to
/// the first one, and only from there does it ask before leaving the app, so a
/// stray swipe never closes MedAID during an emergency.
class RoleShellScaffold extends StatelessWidget {
  const RoleShellScaffold({super.key, required this.navigationShell, required this.items});

  final StatefulNavigationShell navigationShell;
  final List<NavItem> items;

  Future<void> _onBack(BuildContext context) async {
    if (navigationShell.currentIndex != 0) {
      navigationShell.goBranch(0);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final leave = await showConfirmationDialog(
      context,
      title: l10n.exitConfirmTitle,
      message: l10n.exitConfirmMessage,
      confirmLabel: l10n.exitConfirmAction,
    );
    if (leave) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_onBack(context));
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: BottomNavBar(
          items: items,
          currentIndex: navigationShell.currentIndex,
          onSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}
