import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/generated/app_localizations.dart';
import '../../utils/error_messages.dart';
import '../empty_states/error_view.dart';
import 'loading_view.dart';

/// Renders loading, error (with retry), empty and data states consistently
/// for any network-backed [AsyncValue] (doc 23).
///
/// Previous data stays visible while refreshing.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.isEmpty,
    this.empty,
    this.loadingMessage,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final String? loadingMessage;

  @override
  Widget build(BuildContext context) {
    if (value.hasValue) {
      final current = value.requireValue;
      if (empty != null && (isEmpty?.call(current) ?? false)) return empty!;
      return data(current);
    }
    if (value.hasError) {
      return ErrorView(
        message: localizedErrorMessage(AppLocalizations.of(context), value.error),
        onRetry: onRetry,
      );
    }
    return LoadingView(message: loadingMessage);
  }
}
