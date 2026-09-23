import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/dialogs/app_snackbar.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_form_layout.dart';

/// Forced for admin-created accounts (OQ-09); also reachable from profiles.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key, this.forced = true});

  /// Forced for admin-created accounts; otherwise opened from a profile.
  final bool forced;

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final l10n = AppLocalizations.of(context);
    setState(() => _submitting = true);
    try {
      await ref
          .read(authProvider.notifier)
          .changePassword(currentPassword: _current.text, newPassword: _new.text);
      if (!mounted) return;
      showAppSnackbar(context, l10n.authPasswordChanged, tone: AppTone.success);
      if (!widget.forced) context.pop();
    } catch (error) {
      if (mounted) {
        showAppSnackbar(context, localizedErrorMessage(l10n, error), tone: AppTone.danger);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = FormValidators(l10n);
    const gap = SizedBox(height: AppSpacing.lg);

    return AuthFormLayout(
      title: l10n.authChangePasswordTitle,
      subtitle: l10n.authChangePasswordSubtitle,
      showLanguageSelector: false,
      onBack: widget.forced ? null : () => context.pop(),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                label: l10n.authCurrentPasswordLabel,
                controller: _current,
                isPassword: true,
                prefixIcon: Icons.lock_clock_outlined,
                textInputAction: TextInputAction.next,
                validator: v.required,
              ),
              gap,
              AppTextField(
                label: l10n.authNewPasswordLabel,
                controller: _new,
                isPassword: true,
                prefixIcon: Icons.lock_outline_rounded,
                helperText: l10n.validationPassword,
                textInputAction: TextInputAction.next,
                validator: v.newPassword(() => _current.text),
              ),
              gap,
              AppTextField(
                label: l10n.authConfirmPasswordLabel,
                controller: _confirm,
                isPassword: true,
                prefixIcon: Icons.lock_outline_rounded,
                textInputAction: TextInputAction.done,
                validator: v.matches(() => _new.text),
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryButton(
          label: l10n.authChangePasswordButton,
          isLoading: _submitting,
          onPressed: _submit,
        ),
        if (widget.forced) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _submitting ? null : () => ref.read(authProvider.notifier).logout(),
            child: Text(l10n.authLogout),
          ),
        ],
      ],
    );
  }
}
