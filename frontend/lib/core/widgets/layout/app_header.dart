import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Large, left-aligned screen title with optional subtitle, back button and actions.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showBack,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// Defaults to showing a back button when the route can pop.
  final bool? showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final canPop = GoRouter.maybeOf(context)?.canPop() ?? Navigator.of(context).canPop();
    final back = showBack ?? canPop;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.md,
        AppSpacing.screen,
        AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (back) ...[
            IconButton.filledTonal(
              tooltip: AppLocalizations.of(context).commonBack,
              onPressed: onBack ?? () => context.pop(),
              style: IconButton.styleFrom(backgroundColor: context.colors.surface),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textStyles.headlineSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
