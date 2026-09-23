import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/external_actions.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/buttons/primary_button.dart';
import '../../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../../core/widgets/cards/app_card.dart';
import '../../../../../core/widgets/chips/status_chip.dart';
import '../../../../../core/widgets/layout/app_scaffold.dart';
import '../../../../../core/widgets/layout/section_header.dart';
import '../../../../../core/widgets/loaders/async_value_view.dart';
import '../../../../../core/widgets/map/location_map.dart';
import '../../../../../core/widgets/map/map_marker.dart';
import '../../application/facilities_providers.dart';
import '../../domain/facility.dart';

class FacilityDetailsScreen extends ConsumerWidget {
  const FacilityDetailsScreen({super.key, required this.type, required this.id});

  final FacilityType type;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final key = (type: type, id: id);
    final detail = ref.watch(facilityDetailProvider(key));

    return AppScaffold(
      title: detail.value?.name ?? l10n.commonDetails,
      subtitle: type == FacilityType.camp ? l10n.facilityTypeCamp : l10n.facilityTypeHospital,
      scrollable: false,
      body: AsyncValueView<Facility>(
        value: detail,
        onRetry: () => ref.invalidate(facilityDetailProvider(key)),
        data: (facility) => _FacilityDetails(facility: facility),
      ),
    );
  }
}

class _FacilityDetails extends ConsumerWidget {
  const _FacilityDetails({required this.facility});

  final Facility facility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final format = AppFormatters.of(context);
    final actions = ref.read(externalActionsProvider);
    final phone = facility.contactPhone;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        SizedBox(
          height: AppSizes.mapPreviewHeight,
          child: LocationMap(
            center: facility.location.toLatLng(),
            interactive: false,
            markers: [
              MapMarkerData(
                id: facility.id,
                point: facility.location.toLatLng(),
                kind: facility.isCamp ? MapMarkerKind.camp : MapMarkerKind.hospital,
                label: facility.name,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: l10n.facilityDirections,
          icon: Icons.directions_rounded,
          onPressed: () => actions.directionsTo(facility.location),
        ),
        if (phone != null && phone.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: '${l10n.facilityCall} · $phone',
            icon: Icons.call_rounded,
            onPressed: () => actions.call(phone),
          ),
        ],
        if (facility.isCamp && facility.startDateTime != null && facility.endDateTime != null) ...[
          SectionHeader(title: l10n.facilityValidityTitle),
          AppCard(
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, color: context.palette.success),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    format.dateTimeRange(facility.startDateTime!, facility.endDateTime!),
                    style: context.textStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (facility.description != null && facility.description!.isNotEmpty) ...[
          SectionHeader(title: l10n.facilityAbout),
          Text(facility.description!, style: context.textStyles.bodyMedium),
        ],
        if (facility.address != null && facility.address!.isNotEmpty) ...[
          SectionHeader(title: l10n.facilityAddressTitle),
          Text(facility.address!, style: context.textStyles.bodyMedium),
        ],
        if (facility.services.isNotEmpty || facility.hasEmergencyDepartment) ...[
          SectionHeader(title: l10n.facilityServicesTitle),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (facility.hasEmergencyDepartment)
                StatusChip(label: l10n.facilityEmergencyDept, tone: AppTone.emergency),
              for (final service in facility.services) StatusChip(label: service),
            ],
          ),
        ],
        if (facility.contactName != null && facility.contactName!.isNotEmpty) ...[
          SectionHeader(title: l10n.facilityContactTitle),
          Text(facility.contactName!, style: context.textStyles.bodyMedium),
        ],
      ],
    );
  }
}
