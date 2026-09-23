import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../chips/status_chip.dart';
import 'app_card.dart';

enum DocumentTileState { empty, uploading, uploaded, approved, rejected }

/// One required volunteer document: pick/replace, progress and review status.
class DocumentUploadTile extends StatelessWidget {
  const DocumentUploadTile({
    super.key,
    required this.title,
    required this.state,
    required this.actionLabel,
    this.subtitle,
    this.fileName,
    this.statusLabel,
    this.progress,
    this.note,
    this.onAction,
  });

  final String title;
  final DocumentTileState state;

  /// "Upload" or "Replace".
  final String actionLabel;
  final String? subtitle;
  final String? fileName;
  final String? statusLabel;

  /// 0..1 while uploading.
  final double? progress;

  /// Reviewer note, shown for rejected documents.
  final String? note;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (tone, icon) = switch (state) {
      DocumentTileState.empty => (AppTone.neutral, Icons.upload_file_rounded),
      DocumentTileState.uploading => (AppTone.info, Icons.cloud_upload_rounded),
      DocumentTileState.uploaded => (AppTone.info, Icons.description_rounded),
      DocumentTileState.approved => (AppTone.success, Icons.verified_rounded),
      DocumentTileState.rejected => (AppTone.danger, Icons.report_problem_rounded),
    };
    final colors = context.palette.tone(tone);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.avatarMd,
                height: AppSizes.avatarMd,
                decoration: BoxDecoration(color: colors.background, borderRadius: AppRadii.mdAll),
                child: Icon(icon, color: colors.foreground),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.textStyles.titleSmall),
                    if (fileName != null || subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        fileName ?? subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (statusLabel != null) StatusChip(label: statusLabel!, tone: tone),
            ],
          ),
          if (state == DocumentTileState.uploading) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: AppRadii.pillAll,
              child: LinearProgressIndicator(value: progress),
            ),
          ],
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(note!, style: context.textStyles.bodySmall?.copyWith(color: colors.foreground)),
          ],
          if (state != DocumentTileState.uploading && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
