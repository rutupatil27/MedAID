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
import '../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../shared/models/app_user.dart';
import '../../application/account_controller.dart';

/// Name and phone. Used by every role's profile.
class EditAccountScreen extends ConsumerWidget {
  const EditAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final account = ref.watch(accountProvider);

    return AppScaffold(
      title: l10n.profileEditTitle,
      scrollable: false,
      body: AsyncValueView<AppUser>(
        value: account,
        onRetry: () => ref.invalidate(accountProvider),
        data: (user) => _EditForm(user: user),
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({required this.user});

  final AppUser user;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.name);
  late final _phone = TextEditingController(text: widget.user.phone ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(accountProvider.notifier)
          .updateDetails(name: _name.text.trim(), phone: _phone.text.trim());
      if (!mounted) return;
      showAppSnackbar(context, l10n.profileSaved, tone: AppTone.success);
      context.pop();
    } catch (error) {
      if (mounted) {
        showAppSnackbar(context, localizedErrorMessage(l10n, error), tone: AppTone.danger);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = FormValidators(l10n);

    return Form(
      key: _formKey,
      child: ListView(
        children: [
          AppTextField(
            label: l10n.authNameLabel,
            controller: _name,
            textCapitalization: TextCapitalization.words,
            validator: v.name,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: l10n.authPhoneLabel,
            controller: _phone,
            keyboardType: TextInputType.phone,
            validator: v.optionalPhone,
          ),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(label: l10n.commonSave, isLoading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
