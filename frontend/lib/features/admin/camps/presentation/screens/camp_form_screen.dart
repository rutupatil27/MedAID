import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../core/location/location_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/error_messages.dart';
import '../../../../../core/utils/form_validators.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/buttons/danger_button.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/dialogs/app_snackbar.dart';
import '../../../../../core/widgets/dialogs/confirmation_dialog.dart';
import '../../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/layout/section_header.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../../core/widgets/map/location_map.dart';
import '../../../../../core/widgets/map/map_marker.dart';
import '../../../../../shared/models/geo_point.dart';
import '../../application/admin_camp_providers.dart';
import '../../domain/admin_camp.dart';

/// Create/Edit Camp (doc 27, admin #13). [campId] null creates a new camp.
class CampFormScreen extends ConsumerWidget {
  const CampFormScreen({super.key, this.campId});

  final String? campId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = campId;
    return AppScaffold(
      title: id == null ? l10n.adminCreateCamp : l10n.adminEditCamp,
      scrollable: false,
      body: id == null
          ? const _CampForm()
          : AsyncValueView<AdminCamp>(
              value: ref.watch(adminCampProvider(id)),
              onRetry: () => ref.invalidate(adminCampProvider(id)),
              data: (camp) => _CampForm(existing: camp),
            ),
    );
  }
}

class _CampForm extends ConsumerStatefulWidget {
  const _CampForm({this.existing});

  final AdminCamp? existing;

  @override
  ConsumerState<_CampForm> createState() => _CampFormState();
}

class _CampFormState extends ConsumerState<_CampForm> {
  static const _defaultCenter = LatLng(20.0086, 73.7925);

  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _description = TextEditingController(text: widget.existing?.description);
  late final _address = TextEditingController(text: widget.existing?.address);
  late final _services = TextEditingController(text: widget.existing?.services.join(', '));
  late final _contactName = TextEditingController(text: widget.existing?.contactName);
  late final _contactPhone = TextEditingController(text: widget.existing?.contactPhone);
  late GeoPoint? _location = widget.existing?.location;
  late DateTime _start = widget.existing?.startDateTime ?? DateTime.now();
  late DateTime _end =
      widget.existing?.endDateTime ?? DateTime.now().add(const Duration(hours: 12));
  late bool _active = widget.existing?.isActive ?? true;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _description, _address, _services, _contactName, _contactPhone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _useMyLocation() async {
    final service = ref.read(locationServiceProvider);
    await service.requestAccess();
    final fix = await service.currentFix();
    if (fix != null && mounted) setState(() => _location = fix.point);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final location = _location;
    if (location == null) {
      showAppSnackbar(context, l10n.adminCampLocationRequired, tone: AppTone.danger);
      return;
    }
    if (!_end.isAfter(_start)) {
      showAppSnackbar(context, l10n.adminCampEndBeforeStart, tone: AppTone.danger);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(adminCampsProvider.notifier)
          .save(
            CampDraft(
              name: _name.text.trim(),
              description: _description.text.trim(),
              location: location,
              address: _address.text.trim(),
              services: _services.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList(),
              contactName: _contactName.text.trim(),
              contactPhone: _contactPhone.text.trim(),
              startDateTime: _start,
              endDateTime: _end,
              isActive: _active,
            ),
            id: widget.existing?.id,
          );
      if (!mounted) return;
      showAppSnackbar(context, l10n.adminCampSaved, tone: AppTone.success);
      context.pop();
    } catch (error) {
      if (mounted) {
        showAppSnackbar(context, localizedErrorMessage(l10n, error), tone: AppTone.danger);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmationDialog(
      context,
      title: l10n.adminCampDelete,
      message: l10n.adminCampDeleteConfirm,
      confirmLabel: l10n.commonDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(adminCampsProvider.notifier).delete(widget.existing!.id);
      if (!mounted) return;
      showAppSnackbar(context, l10n.adminCampDeleted);
      context.pop();
    } catch (error) {
      if (mounted) {
        showAppSnackbar(context, localizedErrorMessage(l10n, error), tone: AppTone.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = AppFormatters.of(context);
    final v = FormValidators(l10n);
    const gap = SizedBox(height: AppSpacing.lg);
    final location = _location;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          AppTextField(label: l10n.adminCampName, controller: _name, validator: v.required),
          gap,
          AppTextField(label: l10n.adminCampDescription, controller: _description, maxLines: 3),
          gap,
          AppTextField(label: l10n.adminCampAddress, controller: _address, validator: v.required),
          gap,
          AppTextField(label: l10n.adminCampServices, controller: _services),
          gap,
          AppTextField(label: l10n.adminCampContactName, controller: _contactName),
          gap,
          AppTextField(
            label: l10n.adminCampContactPhone,
            controller: _contactPhone,
            keyboardType: TextInputType.phone,
            validator: v.optionalPhone,
          ),
          SectionHeader(title: l10n.adminCampStart),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await _pickDateTime(_start);
              if (picked != null) setState(() => _start = picked);
            },
            icon: const Icon(Icons.event_available_rounded),
            label: Text(format.dateTime(_start)),
          ),
          SectionHeader(title: l10n.adminCampEnd),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await _pickDateTime(_end);
              if (picked != null) setState(() => _end = picked);
            },
            icon: const Icon(Icons.event_busy_rounded),
            label: Text(format.dateTime(_end)),
          ),
          gap,
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.adminCampActive),
            value: _active,
            onChanged: (value) => setState(() => _active = value),
          ),
          SectionHeader(
            title: l10n.adminCampLocation,
            actionLabel: l10n.adminCampUseMyLocation,
            onAction: _useMyLocation,
          ),
          Text(l10n.adminCampLocationHint, style: context.textStyles.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppSizes.mapPreviewHeight * 1.4,
            child: LocationMap(
              center: location?.toLatLng() ?? _defaultCenter,
              markers: [
                if (location != null)
                  MapMarkerData(id: 'camp', point: location.toLatLng(), kind: MapMarkerKind.camp),
              ],
              onTap: (point) => setState(
                () => _location = GeoPoint(latitude: point.latitude, longitude: point.longitude),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(label: l10n.commonSave, isLoading: _saving, onPressed: _save),
          if (widget.existing != null) ...[
            const SizedBox(height: AppSpacing.md),
            DangerButton(
              label: l10n.adminCampDelete,
              outlined: true,
              onPressed: _saving ? null : _delete,
            ),
          ],
        ],
      ),
    );
  }
}
