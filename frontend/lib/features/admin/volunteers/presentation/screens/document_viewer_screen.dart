import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../../core/widgets/empty_states/empty_state_view.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../domain/document_preview.dart';

/// Shows a verification document inside the app, so an admin never has to hand
/// a signed link to a browser. Images are shown directly and can be zoomed;
/// PDFs still open outside, because the app has no PDF renderer.
class DocumentViewerScreen extends StatelessWidget {
  const DocumentViewerScreen({super.key, this.preview});

  final DocumentPreview? preview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final document = preview;

    return AppScaffold(
      title: document?.title ?? l10n.adminViewDocument,
      scrollable: false,
      body: switch (document) {
        // Reached without going through the documents list (a restart, say):
        // the signed link only exists there.
        null => EmptyStateView(
          title: l10n.adminDocumentUnavailableTitle,
          message: l10n.adminDocumentUnavailableMessage,
          icon: Icons.description_outlined,
        ),
        final d when d.isImage => _ImageView(url: d.url),
        final d => _UnsupportedView(document: d),
      },
    );
  }
}

class _ImageView extends StatelessWidget {
  const _ImageView({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadii.lgAll,
            child: ColoredBox(
              color: context.palette.surfaceMuted,
              child: InteractiveViewer(
                maxScale: 6,
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (context, _, _) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      child: Text(
                        l10n.adminDocumentLoadFailed,
                        textAlign: TextAlign.center,
                        style: context.textStyles.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.adminDocumentZoomHint,
          style: context.textStyles.bodySmall?.copyWith(color: context.palette.textSecondary),
        ),
      ],
    );
  }
}

class _UnsupportedView extends StatelessWidget {
  const _UnsupportedView({required this.document});

  final DocumentPreview document;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          color: context.palette.surfaceMuted,
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_rounded, color: context.palette.info),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(l10n.adminDocumentPdfNotice, style: context.textStyles.bodyMedium),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SecondaryButton(
          key: const Key('admin.openDocumentExternally'),
          label: l10n.adminDocumentOpenExternally,
          icon: Icons.open_in_new_rounded,
          onPressed: () => launchUrl(Uri.parse(document.url), mode: LaunchMode.externalApplication),
        ),
      ],
    );
  }
}
