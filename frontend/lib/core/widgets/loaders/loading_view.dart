import 'package:flutter/material.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Full-area loading state.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message ?? AppLocalizations.of(context).commonLoading,
              textAlign: TextAlign.center,
              style: context.textStyles.bodyMedium?.copyWith(color: context.palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
