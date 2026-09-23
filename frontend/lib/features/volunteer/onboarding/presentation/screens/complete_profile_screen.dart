import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/error_messages.dart';
import '../../../../../core/utils/form_validators.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/dialogs/app_snackbar.dart';
import '../../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../../shared/models/volunteer.dart';
import '../../../application/volunteer_controller.dart';

/// Complete Profile (doc 27, volunteer #2). Also used to edit details later.
class CompleteProfileScreen extends ConsumerWidget {
  const CompleteProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      title: l10n.profileCompleteTitle,
      subtitle: l10n.profileCompleteSubtitle,
      scrollable: false,
      body: AsyncValueView<Volunteer>(
        value: ref.watch(volunteerProvider),
        onRetry: () => ref.invalidate(volunteerProvider),
        data: (v) => _ProfileForm(profile: v.profile),
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.profile});

  final VolunteerProfile profile;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _phone = TextEditingController(text: widget.profile.phone ?? '');
  late final _address = TextEditingController(text: widget.profile.address ?? '');
  late final _city = TextEditingController(text: widget.profile.city ?? '');
  late final _contactName = TextEditingController(text: widget.profile.emergencyContactName ?? '');
  late final _contactPhone = TextEditingController(
    text: widget.profile.emergencyContactPhone ?? '',
  );
  late final _languages = TextEditingController(text: widget.profile.languages.join(', '));
  late final _skills = TextEditingController(text: widget.profile.skills.join(', '));
  bool _saving = false;

  List<TextEditingController> get _all => [
    _phone,
    _address,
    _city,
    _contactName,
    _contactPhone,
    _languages,
    _skills,
  ];

  static List<String> _split(String text) =>
      text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(volunteerProvider.notifier).updateProfile({
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'city': _city.text.trim(),
        'emergencyContactName': _contactName.text.trim(),
        'emergencyContactPhone': _contactPhone.text.trim(),
        'languages': _split(_languages.text),
        'skills': _split(_skills.text),
      });
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
    String? phoneRequired(String? value) => v.required(value) ?? v.optionalPhone(value);
    const gap = SizedBox(height: AppSpacing.lg);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          AppTextField(
            key: const Key('volunteer.phone'),
            label: l10n.volunteerPhone,
            controller: _phone,
            keyboardType: TextInputType.phone,
            validator: phoneRequired,
          ),
          gap,
          AppTextField(
            label: l10n.volunteerAddress,
            controller: _address,
            maxLines: 2,
            validator: v.required,
          ),
          gap,
          AppTextField(label: l10n.volunteerCity, controller: _city, validator: v.required),
          gap,
          AppTextField(
            label: l10n.medicalEmergencyContactName,
            controller: _contactName,
            textCapitalization: TextCapitalization.words,
            validator: v.required,
          ),
          gap,
          AppTextField(
            label: l10n.medicalEmergencyContactPhone,
            controller: _contactPhone,
            keyboardType: TextInputType.phone,
            validator: phoneRequired,
          ),
          gap,
          AppTextField(label: l10n.volunteerLanguages, controller: _languages),
          gap,
          AppTextField(label: l10n.volunteerSkills, controller: _skills),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(label: l10n.commonSave, isLoading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
