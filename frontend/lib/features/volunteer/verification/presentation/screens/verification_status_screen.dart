import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../app/router/app_routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../../core/widgets/chips/status_chip.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../../shared/enums/volunteer_enums.dart';
import '../../../../../shared/models/volunteer.dart';
import '../../../application/volunteer_controller.dart';

/// Verification Pending / Result (doc 27, volunteer #4-5).
class VerificationStatusScreen extends ConsumerWidget {
  const VerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return AppScaffold(
      title: l10n.verificationTitle,
      onRefresh: () => ref.read(volunteerProvider.notifier).refresh(),
      body: AsyncValueView<Volunteer>(
        value: ref.watch(volunteerProvider),
        onRetry: () => ref.invalidate(volunteerProvider),
        data: (v) {
          final status = v.verificationStatus;
          final (IconData icon, String message) = switch (status) {
            VerificationStatus.notSubmitted => (
              Icons.assignment_outlined,
              l10n.verificationNotSubmittedMessage,
            ),
            VerificationStatus.pending => (
              Icons.hourglass_top_rounded,
              l10n.verificationPendingMessage,
            ),
            VerificationStatus.approved => (
              Icons.verified_rounded,
              l10n.verificationApprovedMessage,
            ),
            VerificationStatus.rejected => (
              Icons.report_gmailerrorred_rounded,
              l10n.verificationRejectedMessage,
            ),
          };
          final colors = context.palette.tone(status.tone);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              CircleAvatar(
                radius: AppSizes.iconHero,
                backgroundColor: colors.background,
                child: Icon(icon, size: AppSizes.iconHero, color: colors.foreground),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: StatusChip(label: status.label(l10n), tone: status.tone),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(message, textAlign: TextAlign.center, style: context.textStyles.bodyLarge),
              if (status == VerificationStatus.rejected && v.rejectionReason != null) ...[
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  color: colors.background,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.verificationReasonLabel, style: context.textStyles.labelMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(v.rejectionReason!, style: context.textStyles.bodyMedium),
                    ],
                  ),
                ),
              ],
              if (status == VerificationStatus.rejected ||
                  status == VerificationStatus.notSubmitted) ...[
                const SizedBox(height: AppSpacing.xxl),
                PrimaryButton(
                  label: l10n.verificationUpdateDocuments,
                  icon: Icons.upload_file_rounded,
                  onPressed: () => context.push(AppRoutes.volunteerDocuments),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
