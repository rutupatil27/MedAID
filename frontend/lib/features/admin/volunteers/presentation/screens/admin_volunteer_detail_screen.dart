import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../app/router/app_routes.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/error_messages.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/buttons/danger_button.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../../core/widgets/chips/status_chip.dart';
import '../../../../../core/widgets/dialogs/app_snackbar.dart';
import '../../../../../core/widgets/dialogs/confirmation_dialog.dart';
import '../../../../../core/widgets/dialogs/note_sheet.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/layout/section_header.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../../core/widgets/misc/bullet_list.dart';
import '../../../../../core/widgets/misc/profile_avatar.dart';
import '../../../../../shared/enums/volunteer_enums.dart';
import '../../../../../shared/models/volunteer.dart';
import '../../application/admin_volunteer_providers.dart';
import '../../domain/document_preview.dart';

/// Volunteer Details + Document Review (doc 27, admin #7, #9).
class AdminVolunteerDetailScreen extends ConsumerWidget {
  const AdminVolunteerDetailScreen({super.key, required this.volunteerId});

  final String volunteerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      title: l10n.adminVolunteerDetails,
      scrollable: false,
      body: AsyncValueView<Volunteer>(
        value: ref.watch(adminVolunteerProvider(volunteerId)),
        onRetry: () => ref.invalidate(adminVolunteerProvider(volunteerId)),
        data: (v) => _Body(volunteer: v),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.volunteer});

  final Volunteer volunteer;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  AdminVolunteerController get _controller =>
      ref.read(adminVolunteerProvider(widget.volunteer.id).notifier);

  Future<void> _run(Future<void> Function() action, String success) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showAppSnackbar(context, success, tone: AppTone.success);
    } catch (error) {
      if (mounted) {
        showAppSnackbar(context, localizedErrorMessage(l10n, error), tone: AppTone.danger);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final l10n = AppLocalizations.of(context);
    final reason = await showNoteSheet(
      context,
      title: l10n.adminReject,
      label: l10n.adminRejectReasonLabel,
      submitLabel: l10n.adminReject,
    );
    if (reason != null) await _run(() => _controller.reject(reason), l10n.adminRejected);
  }

  Future<void> _toggleSuspension() async {
    final l10n = AppLocalizations.of(context);
    final suspend = !widget.volunteer.account.isSuspended;
    if (suspend) {
      final confirmed = await showConfirmationDialog(
        context,
        title: l10n.adminSuspendConfirmTitle,
        message: l10n.adminSuspendConfirmMessage,
        confirmLabel: l10n.adminSuspend,
        destructive: true,
      );
      if (!confirmed) return;
    }
    await _run(() => _controller.setSuspended(suspended: suspend), l10n.adminAccountUpdated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = AppFormatters.of(context);
    final v = widget.volunteer;
    final p = v.profile;
    final documents = ref.watch(adminVolunteerDocumentsProvider(v.id));
    const line = AppFormatters.labelled;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        Row(
          children: [
            ProfileAvatar(name: v.account.name, size: AppSizes.avatarLg),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.account.name, style: context.textStyles.titleLarge),
                  Text(v.account.email, style: context.textStyles.bodySmall),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      StatusChip(
                        label: v.verificationStatus.label(l10n),
                        tone: v.verificationStatus.tone,
                      ),
                      StatusChip(label: v.status.label(l10n), tone: v.status.tone, showDot: true),
                      if (v.account.isSuspended)
                        StatusChip(label: l10n.adminSuspended, tone: AppTone.danger),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (v.rejectionReason != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            color: context.palette.tone(AppTone.danger).background,
            child: Text(line(l10n.verificationReasonLabel, v.rejectionReason)),
          ),
        ],
        if (v.verificationStatus == VerificationStatus.pending) ...[
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            key: const Key('admin.approve'),
            label: l10n.adminApprove,
            icon: Icons.verified_rounded,
            isLoading: _busy,
            onPressed: () => _run(_controller.approve, l10n.adminApproved),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(label: l10n.adminReject, onPressed: _busy ? null : _reject),
        ],
        SectionHeader(title: l10n.adminProfileSection),
        AppCard(
          child: BulletList(
            icon: Icons.info_outline_rounded,
            items: [
              line(l10n.volunteerPhone, p.phone),
              line(l10n.volunteerAddress, p.address),
              line(l10n.volunteerCity, p.city),
              line(l10n.medicalEmergencyContactName, p.emergencyContactName),
              line(l10n.medicalEmergencyContactPhone, p.emergencyContactPhone),
              line(l10n.volunteerLanguages, p.languages.join(', ')),
              line(l10n.volunteerSkills, p.skills.join(', ')),
              if (v.location?.updatedAt != null)
                line(l10n.adminLastLocation, format.relativeTime(v.location!.updatedAt!)),
            ],
          ),
        ),
        SectionHeader(title: l10n.adminDocumentsSection),
        AsyncValueView(
          value: documents,
          onRetry: () => ref.invalidate(adminVolunteerDocumentsProvider(v.id)),
          isEmpty: (items) => items.isEmpty,
          empty: Text(l10n.adminNoDocuments, style: context.textStyles.bodySmall),
          data: (items) => Column(
            children: [
              for (final item in items) ...[
                AppCard(
                  child: Row(
                    children: [
                      Icon(
                        item.document.mimeType == 'application/pdf'
                            ? Icons.picture_as_pdf_rounded
                            : Icons.image_rounded,
                        color: context.palette.info,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.document.type.label(l10n),
                              style: context.textStyles.titleSmall,
                            ),
                            Text(
                              item.document.status.label(l10n),
                              style: context.textStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (item.url != null)
                        TextButton(
                          key: const Key('admin.viewDocument'),
                          onPressed: () => context.push(
                            AppRoutes.adminVolunteerDocument(v.id),
                            extra: DocumentPreview(
                              title: item.document.type.label(l10n),
                              url: item.url!,
                              mimeType: item.document.mimeType,
                            ),
                          ),
                          child: Text(l10n.adminViewDocument),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (v.account.isSuspended)
          SecondaryButton(label: l10n.adminReactivate, onPressed: _busy ? null : _toggleSuspension)
        else
          DangerButton(
            label: l10n.adminSuspend,
            outlined: true,
            onPressed: _busy ? null : _toggleSuspension,
          ),
      ],
    );
  }
}
