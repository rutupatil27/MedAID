import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/error_messages.dart';
import '../../../../../core/utils/form_validators.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../../core/widgets/dialogs/app_snackbar.dart';
import '../../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../application/admin_volunteer_providers.dart';

/// Create Volunteer (doc 27, admin #6). Shows the temporary password once.
class CreateVolunteerScreen extends ConsumerStatefulWidget {
  const CreateVolunteerScreen({super.key});

  @override
  ConsumerState<CreateVolunteerScreen> createState() => _CreateVolunteerScreenState();
}

class _CreateVolunteerScreenState extends ConsumerState<CreateVolunteerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _username, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _create() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(adminVolunteersProvider.notifier)
          .create(
            name: _name.text.trim(),
            email: _email.text.trim(),
            username: _username.text.trim(),
            phone: _phone.text.trim(),
          );
      if (!mounted) return;
      setState(() => _saving = false);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _TemporaryPasswordDialog(
          name: result.volunteer.account.name,
          password: result.temporaryPassword,
        ),
      );
      if (mounted) context.pop();
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException && error.code == ApiErrorCodes.conflict
          ? l10n.authAccountExists
          : localizedErrorMessage(l10n, error);
      showAppSnackbar(context, message, tone: AppTone.danger);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = FormValidators(l10n);
    const gap = SizedBox(height: AppSpacing.lg);

    return AppScaffold(
      title: l10n.adminCreateVolunteer,
      subtitle: l10n.adminCreateVolunteerSubtitle,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              key: const Key('createVolunteer.name'),
              label: l10n.authNameLabel,
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: v.name,
            ),
            gap,
            AppTextField(
              key: const Key('createVolunteer.email'),
              label: l10n.authEmailLabel,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: v.email,
            ),
            gap,
            AppTextField(
              key: const Key('createVolunteer.username'),
              label: l10n.authUsernameLabel,
              controller: _username,
              validator: v.username,
            ),
            gap,
            AppTextField(
              label: l10n.authPhoneLabel,
              controller: _phone,
              keyboardType: TextInputType.phone,
              validator: v.optionalPhone,
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              key: const Key('createVolunteer.submit'),
              label: l10n.adminCreateVolunteer,
              isLoading: _saving,
              onPressed: _create,
            ),
          ],
        ),
      ),
    );
  }
}

class _TemporaryPasswordDialog extends StatelessWidget {
  const _TemporaryPasswordDialog({required this.name, required this.password});

  final String name;
  final String password;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.adminVolunteerCreatedTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.adminTemporaryPasswordMessage(name)),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            color: context.palette.surfaceMuted,
            child: SelectableText(
              password,
              key: const Key('createVolunteer.password'),
              textAlign: TextAlign.center,
              style: context.textStyles.titleLarge?.copyWith(letterSpacing: 2),
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: password));
            if (context.mounted) showAppSnackbar(context, l10n.adminCopied);
          },
          icon: const Icon(Icons.copy_rounded),
          label: Text(l10n.adminCopy),
        ),
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.commonOk)),
      ],
    );
  }
}
