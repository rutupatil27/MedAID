import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'app_header.dart';

/// Standard screen frame: header, constrained content width, safe areas,
/// optional pull-to-refresh and a pinned bottom action area.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.subtitle,
    this.actions = const [],
    this.showBack,
    this.onRefresh,
    this.bottomAction,
    this.floatingActionButton,
    this.scrollable = true,
    this.padded = true,
  });

  final Widget body;
  final String? title;
  final String? subtitle;
  final List<Widget> actions;
  final bool? showBack;
  final Future<void> Function()? onRefresh;

  /// Pinned above the bottom inset, e.g. a PrimaryButton.
  final Widget? bottomAction;
  final Widget? floatingActionButton;

  /// Wrap [body] in a scroll view. Disable for lists/maps that scroll themselves.
  final bool scrollable;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    Widget content = padded ? Padding(padding: AppSpacing.screenPadding, child: body) : body;

    if (scrollable) {
      content = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: content,
      );
    }
    if (onRefresh != null) {
      content = RefreshIndicator(onRefresh: onRefresh!, child: content);
    }

    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        bottom: bottomAction == null,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  AppHeader(
                    title: title!,
                    subtitle: subtitle,
                    actions: actions,
                    showBack: showBack,
                  ),
                Expanded(child: content),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: bottomAction == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.sm,
                  AppSpacing.screen,
                  AppSpacing.lg,
                ),
                child: bottomAction,
              ),
            ),
    );
  }
}
