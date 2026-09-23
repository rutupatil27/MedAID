import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../core/files/document_picker.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/error_messages.dart';
import '../../../../../core/widgets/cards/document_upload_tile.dart';
import '../../../../../core/widgets/dialogs/app_snackbar.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../../shared/enums/volunteer_enums.dart';
import '../../../../../shared/models/volunteer.dart';
import '../../../application/volunteer_controller.dart';

/// Document Upload (doc 27, volunteer #3). Files go to the backend, which
/// stores them privately in Cloudinary (D-011).
class DocumentUploadScreen extends ConsumerWidget {
  const DocumentUploadScreen({super.key});

  Future<void> _upload(BuildContext context, WidgetRef ref, DocumentType type) async {
    final l10n = AppLocalizations.of(context);
    final picked = await ref.read(documentPickerProvider).pick();
    if (picked == null) return;
    try {
      final before = ref.read(volunteerProvider).value?.verificationStatus;
      await ref.read(volunteerProvider.notifier).uploadDocument(type, picked);
      final after = ref.read(volunteerProvider).value?.verificationStatus;
      if (!context.mounted) return;
      final submitted = before != VerificationStatus.pending && after == VerificationStatus.pending;
      showAppSnackbar(
        context,
        submitted ? l10n.documentsSubmitted : l10n.documentUploaded,
        tone: AppTone.success,
      );
    } catch (error) {
      if (context.mounted) {
        showAppSnackbar(context, localizedErrorMessage(l10n, error), tone: AppTone.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final progress = ref.watch(documentUploadProgressProvider);

    return AppScaffold(
      title: l10n.documentsTitle,
      subtitle: l10n.documentsSubtitle,
      body: AsyncValueView<Volunteer>(
        value: ref.watch(volunteerProvider),
        onRetry: () => ref.invalidate(volunteerProvider),
        data: (volunteer) => Column(
          children: [
            for (final type in [...volunteer.requiredDocuments, DocumentType.other]) ...[
              _tileFor(l10n, volunteer.documentOf(type), type, progress[type], () {
                _upload(context, ref, type);
              }),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tileFor(
    AppLocalizations l10n,
    VolunteerDocumentInfo? doc,
    DocumentType type,
    double? progress,
    VoidCallback onPick,
  ) {
    final state = progress != null
        ? DocumentTileState.uploading
        : switch (doc?.status) {
            null => DocumentTileState.empty,
            DocumentStatus.approved => DocumentTileState.approved,
            DocumentStatus.rejected => DocumentTileState.rejected,
            _ => DocumentTileState.uploaded,
          };
    return DocumentUploadTile(
      title: type.label(l10n),
      state: state,
      fileName: doc?.originalName,
      statusLabel: doc?.status.label(l10n),
      note: doc?.status == DocumentStatus.rejected ? doc?.reviewNote : null,
      progress: progress,
      actionLabel: doc == null ? l10n.commonUpload : l10n.commonReplace,
      onAction: onPick,
    );
  }
}
