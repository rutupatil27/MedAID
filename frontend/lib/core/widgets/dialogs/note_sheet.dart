import 'package:flutter/material.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/form_validators.dart';
import '../buttons/primary_button.dart';
import '../inputs/app_text_field.dart';

/// Bottom sheet asking for a required note (resolve, reject, cancel...).
/// Resolves to the trimmed note, or null when dismissed.
Future<String?> showNoteSheet(
  BuildContext context, {
  required String title,
  required String label,
  required String submitLabel,
  String? hint,
  int maxLength = 1000,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _NoteSheet(
    title: title,
    label: label,
    submitLabel: submitLabel,
    hint: hint,
    maxLength: maxLength,
  ),
);

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({
    required this.title,
    required this.label,
    required this.submitLabel,
    this.hint,
    this.maxLength = 1000,
  });

  final String title;
  final String label;
  final String submitLabel;
  final String? hint;
  final int maxLength;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: context.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              key: const Key('noteSheet.field'),
              label: widget.label,
              hint: widget.hint,
              controller: _note,
              maxLines: 3,
              maxLength: widget.maxLength,
              validator: FormValidators(l10n).required,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              key: const Key('noteSheet.submit'),
              label: widget.submitLabel,
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(_note.text.trim());
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
