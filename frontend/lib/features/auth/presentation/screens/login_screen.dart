import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/generated/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/dialogs/app_snackbar.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_form_layout.dart';

/// Shared login for all roles; the router sends each role to its own home.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      await ref
          .read(authProvider.notifier)
          .login(identifier: _identifier.text.trim(), password: _password.text);
    } catch (error) {
      if (mounted) {
        showAppSnackbar(
          context,
          localizedErrorMessage(AppLocalizations.of(context), error),
          tone: AppTone.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final validators = FormValidators(l10n);

    return AuthFormLayout(
      title: l10n.authLoginTitle,
      subtitle: l10n.authLoginSubtitle,
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                AppTextField(
                  key: const Key('login.identifier'),
                  label: l10n.authIdentifierLabel,
                  controller: _identifier,
                  prefixIcon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username, AutofillHints.email],
                  validator: validators.required,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  key: const Key('login.password'),
                  label: l10n.authPasswordLabel,
                  controller: _password,
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: validators.required,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryButton(
          key: const Key('login.submit'),
          label: l10n.authLoginButton,
          isLoading: _submitting,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.authNoAccount, style: context.textStyles.bodyMedium),
            TextButton(
              onPressed: _submitting ? null : () => context.go(AppRoutes.register),
              child: Text(l10n.authCreateAccountLink),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.authStaffNote, textAlign: TextAlign.center, style: context.textStyles.bodySmall),
      ],
    );
  }
}
