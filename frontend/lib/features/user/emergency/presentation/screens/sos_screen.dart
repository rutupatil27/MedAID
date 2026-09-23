import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../app/router/app_routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/error_messages.dart';
import '../../../../../core/utils/external_actions.dart';
import '../../../../../core/widgets/buttons/danger_button.dart';
import '../../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../application/sos_controller.dart';

/// Emergency confirmation (doc 27 #10): sends the alert immediately after
/// the SOS hold, shows progress, then opens the live status screen.
class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(sosControllerProvider.notifier).send();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sos = ref.watch(sosControllerProvider);

    ref.listen(sosControllerProvider, (_, next) {
      final emergency = next.emergency;
      if (next.step == SosStep.sent && emergency != null) {
        context.replace(AppRoutes.userEmergency(emergency.id));
      }
    });

    final failed = sos.step == SosStep.failed;
    final palette = context.palette;

    return AppScaffold(
      title: failed ? l10n.sosFailedTitle : l10n.sosSendingTitle,
      scrollable: false,
      bottomAction: SecondaryButton(
        label: l10n.commonCallEmergency,
        icon: Icons.call_rounded,
        onPressed: () => ref.read(externalActionsProvider).callEmergency(),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: AppSizes.iconHero,
              backgroundColor: palette.emergencyContainer,
              child: failed
                  ? Icon(
                      Icons.error_outline_rounded,
                      size: AppSizes.iconHero,
                      color: palette.emergency,
                    )
                  : SizedBox.square(
                      dimension: AppSizes.iconHero,
                      child: CircularProgressIndicator(color: palette.emergency, strokeWidth: 5),
                    ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (failed) ...[
              Text(
                l10n.sosFailedMessage,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                localizedErrorMessage(l10n, sos.error),
                textAlign: TextAlign.center,
                style: context.textStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xxl),
              DangerButton(
                label: l10n.commonRetry,
                icon: Icons.refresh_rounded,
                onPressed: () => ref.read(sosControllerProvider.notifier).send(),
              ),
            ] else ...[
              _Step(label: l10n.sosStepLocating, done: sos.step != SosStep.locating),
              const SizedBox(height: AppSpacing.md),
              _Step(
                label: l10n.sosStepSending,
                done: sos.step == SosStep.sent,
                pending: sos.step == SosStep.locating,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.done, this.pending = false});

  final String label;
  final bool done;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: done ? palette.success : palette.textMuted,
          size: AppSizes.iconMd,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: context.textStyles.titleSmall?.copyWith(color: pending ? palette.textMuted : null),
        ),
      ],
    );
  }
}
