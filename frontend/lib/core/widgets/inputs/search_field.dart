import 'package:flutter/material.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Pill-shaped search input with a clear button.
class SearchField extends StatefulWidget {
  const SearchField({super.key, required this.hint, required this.onChanged, this.controller});

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller = widget.controller ?? TextEditingController();

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: AppRadii.pillAll,
      borderSide: BorderSide(color: context.palette.border),
    );

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) => TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: AppLocalizations.of(context).commonClear,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: context.colors.primary, width: 1.6),
          ),
        ),
      ),
    );
  }
}
