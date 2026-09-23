import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/error_messages.dart';
import '../../../../../core/utils/form_validators.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../../core/widgets/dialogs/app_snackbar.dart';
import '../../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/layout/section_header.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../../shared/models/app_user.dart';
import '../../../../auth/application/account_controller.dart';

/// Optional medical details and explicit consent to share them (OQ-16).
class MedicalProfileScreen extends ConsumerWidget {
  const MedicalProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final account = ref.watch(accountProvider);

    return AppScaffold(
      title: l10n.profileMedicalInfo,
      subtitle: l10n.medicalOptionalNote,
      scrollable: false,
      body: AsyncValueView<AppUser>(
        value: account,
        onRetry: () => ref.invalidate(accountProvider),
        data: (user) => _MedicalForm(profile: user.medicalProfile),
      ),
    );
  }
}

class _MedicalForm extends ConsumerStatefulWidget {
  const _MedicalForm({required this.profile});

  final MedicalProfile profile;

  @override
  ConsumerState<_MedicalForm> createState() => _MedicalFormState();
}

class _MedicalFormState extends ConsumerState<_MedicalForm> {
  static const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  final _formKey = GlobalKey<FormState>();
  late final _allergies = TextEditingController(text: widget.profile.allergies ?? '');
  late final _conditions = TextEditingController(text: widget.profile.medicalConditions ?? '');
  late final _contactName = TextEditingController(text: widget.profile.emergencyContactName ?? '');
  late final _contactPhone = TextEditingController(
    text: widget.profile.emergencyContactPhone ?? '',
  );
  late DateTime? _dob = widget.profile.dateOfBirth;
  late String? _gender = widget.profile.gender;
  late String? _bloodGroup = widget.profile.bloodGroup;
  late bool _share = widget.profile.shareWithResponders;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_allergies, _conditions, _contactName, _contactPhone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(accountProvider.notifier)
          .updateMedicalProfile(
            MedicalProfile(
              dateOfBirth: _dob,
              gender: _gender,
              bloodGroup: _bloodGroup,
              allergies: _allergies.text.trim(),
              medicalConditions: _conditions.text.trim(),
              emergencyContactName: _contactName.text.trim(),
              emergencyContactPhone: _contactPhone.text.trim(),
              shareWithResponders: _share,
            ),
          );
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
    final format = AppFormatters.of(context);
    final v = FormValidators(l10n);
    const gap = SizedBox(height: AppSpacing.lg);
    final genders = {
      'MALE': l10n.genderMale,
      'FEMALE': l10n.genderFemale,
      'OTHER': l10n.genderOther,
      'PREFER_NOT_TO_SAY': l10n.genderPreferNotToSay,
    };

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          AppCard(
            color: context.palette.tone(AppTone.emergency).background,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.medicalShareConsent, style: context.textStyles.titleSmall),
              subtitle: Text(l10n.medicalShareConsentHelp),
              value: _share,
              onChanged: (value) => setState(() => _share = value),
            ),
          ),
          SectionHeader(title: l10n.medicalDob),
          OutlinedButton.icon(
            onPressed: _pickDob,
            icon: const Icon(Icons.cake_outlined),
            label: Text(_dob == null ? l10n.commonNotSet : format.date(_dob!)),
          ),
          SectionHeader(title: l10n.medicalGender),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final entry in genders.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _gender == entry.key,
                  onSelected: (selected) => setState(() => _gender = selected ? entry.key : null),
                ),
            ],
          ),
          SectionHeader(title: l10n.medicalBloodGroup),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final group in [..._bloodGroups, 'UNKNOWN'])
                ChoiceChip(
                  label: Text(group == 'UNKNOWN' ? l10n.bloodGroupUnknown : group),
                  selected: _bloodGroup == group,
                  onSelected: (selected) => setState(() => _bloodGroup = selected ? group : null),
                ),
            ],
          ),
          gap,
          AppTextField(
            label: l10n.medicalAllergies,
            controller: _allergies,
            maxLines: 2,
            maxLength: 500,
          ),
          gap,
          AppTextField(
            label: l10n.medicalConditions,
            controller: _conditions,
            maxLines: 2,
            maxLength: 500,
          ),
          gap,
          AppTextField(
            label: l10n.medicalEmergencyContactName,
            controller: _contactName,
            textCapitalization: TextCapitalization.words,
          ),
          gap,
          AppTextField(
            label: l10n.medicalEmergencyContactPhone,
            controller: _contactPhone,
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
