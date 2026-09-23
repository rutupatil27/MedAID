import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/dialogs/app_snackbar.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_form_layout.dart';

/// Self-registration creates a USER account only (D-016).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _username, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      await ref
          .read(authProvider.notifier)
          .register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            username: _username.text.trim(),
            phone: _phone.text.trim(),
            password: _password.text,
          );
    } catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        final message = error is ApiException && error.code == ApiErrorCodes.conflict
            ? l10n.authAccountExists
            : localizedErrorMessage(l10n, error);
        showAppSnackbar(context, message, tone: AppTone.danger);
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
      title: l10n.authRegisterTitle,
      subtitle: l10n.authRegisterSubtitle,
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                AppTextField(
                  label: l10n.authNameLabel,
                  controller: _name,
                  prefixIcon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: v.name,
                ),
                gap,
                AppTextField(
                  label: l10n.authEmailLabel,
                  controller: _email,
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: v.email,
                ),
                gap,
                AppTextField(
                  label: l10n.authUsernameLabel,
                  controller: _username,
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newUsername],
                  validator: v.username,
                ),
                gap,
                AppTextField(
                  label: l10n.authPhoneLabel,
                  controller: _phone,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  validator: v.optionalPhone,
                ),
                gap,
                AppTextField(
                  label: l10n.authPasswordLabel,
                  controller: _password,
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  helperText: l10n.validationPassword,
                  validator: v.password,
                ),
                gap,
                AppTextField(
                  label: l10n.authConfirmPasswordLabel,
                  controller: _confirm,
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: v.matches(() => _password.text),
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryButton(label: l10n.authRegisterButton, isLoading: _submitting, onPressed: _submit),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.authHaveAccount, style: context.textStyles.bodyMedium),
            TextButton(
              onPressed: _submitting ? null : () => context.go(AppRoutes.login),
              child: Text(l10n.authLoginLink),
            ),
          ],
        ),
      ],
    );
  }
}
