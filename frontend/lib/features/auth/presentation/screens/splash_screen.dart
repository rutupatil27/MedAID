import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/widgets/empty_states/error_view.dart';
import '../../application/auth_controller.dart';
import '../widgets/brand_mark.dart';

/// Shown while the session is restored. The router leaves this screen as soon
/// as the auth state is known.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: auth.hasError && !auth.hasValue && !auth.isLoading
            ? ErrorView(
                message: localizedErrorMessage(l10n, auth.error),
                onRetry: () => ref.read(authProvider.notifier).retry(),
              )
            : Center(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrandMark(size: AppSizes.avatarLg),
                      const SizedBox(height: AppSpacing.xl),
                      Text(l10n.appName, style: context.textStyles.headlineMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.appTagline,
                        textAlign: TextAlign.center,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      const CircularProgressIndicator(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
