import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/misc/language_selector.dart';
import 'brand_mark.dart';

/// Shared scaffold for login / register / change-password screens.
class AuthFormLayout extends StatelessWidget {
  const AuthFormLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showLanguageSelector = true,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showLanguageSelector;

  /// Shows a back button when set.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screen,
              vertical: AppSpacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (onBack != null) ...[
                        IconButton.filledTonal(
                          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      const BrandMark(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(title, style: context.textStyles.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    subtitle,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                  if (showLanguageSelector) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const LanguageSelector(),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
