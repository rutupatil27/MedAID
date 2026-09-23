import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../app/router/app_routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/external_actions.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/buttons/emergency_button.dart';
import '../../../../../core/widgets/cards/action_card.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../../core/widgets/cards/emergency_card.dart';
import '../../../../../core/widgets/layout/section_header.dart';
import '../../../../../core/widgets/misc/profile_avatar.dart';
import '../../../../auth/application/auth_controller.dart';
import '../../../../auth/domain/auth_state.dart';
import '../../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../emergency/application/user_emergency_providers.dart';

class UserHomeScreen extends ConsumerWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider).value;
    final name = auth is Authenticated ? auth.user.name : '';
    final openEmergency = ref.watch(openEmergencyProvider).value;
    const gap = SizedBox(height: AppSpacing.md);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(openEmergencyProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.lg,
              AppSpacing.screen,
              AppSpacing.xxl,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.homeGreeting(name), style: context.textStyles.headlineSmall),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          l10n.homeSubtitle,
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: context.palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const NotificationBell(),
                  InkWell(
                    borderRadius: AppRadii.pillAll,
                    onTap: () => context.go(AppRoutes.userProfile),
                    child: ProfileAvatar(name: name),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              if (openEmergency != null) ...[
                EmergencyCard(
                  title: l10n.homeActiveAlertTitle,
                  subtitle: openEmergency.alertNumber,
                  statusLabel: openEmergency.status.label(l10n),
                  statusTone: openEmergency.status.tone,
                  timeLabel: AppFormatters.of(context).relativeTime(openEmergency.createdAt),
                  highlight: true,
                  trailing: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      l10n.homeActiveAlertAction,
                      style: context.textStyles.labelLarge?.copyWith(color: context.colors.primary),
                    ),
                  ),
                  onTap: () => context.push(AppRoutes.userEmergency(openEmergency.id)),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    Text(l10n.sosCardTitle, style: context.textStyles.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.sosCardBody,
                      textAlign: TextAlign.center,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    EmergencyButton(
                      key: const Key('home.sos'),
                      label: l10n.sosLabel,
                      hint: l10n.sosHoldHint,
                      semanticLabel: l10n.sosSemanticLabel,
                      onActivated: () => context.push(AppRoutes.userSos),
                    ),
                    TextButton.icon(
                      onPressed: () => ref.read(externalActionsProvider).callEmergency(),
                      icon: const Icon(Icons.call_rounded),
                      label: Text(l10n.commonCallEmergency),
                    ),
                  ],
                ),
              ),
              SectionHeader(title: l10n.homeQuickActions),
              ActionCard(
                title: l10n.homeSymptomsTitle,
                subtitle: l10n.homeSymptomsSubtitle,
                icon: Icons.medical_information_rounded,
                tone: AppTone.info,
                onTap: () => context.push(AppRoutes.userSymptoms),
              ),
              gap,
              ActionCard(
                title: l10n.homeFacilitiesTitle,
                subtitle: l10n.homeFacilitiesSubtitle,
                icon: Icons.local_hospital_rounded,
                tone: AppTone.success,
                onTap: () => context.go(AppRoutes.userFacilities),
              ),
              gap,
              ActionCard(
                title: l10n.homeHistoryTitle,
                subtitle: l10n.homeHistorySubtitle,
                icon: Icons.history_rounded,
                tone: AppTone.neutral,
                onTap: () => context.go(AppRoutes.userEmergencies),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
