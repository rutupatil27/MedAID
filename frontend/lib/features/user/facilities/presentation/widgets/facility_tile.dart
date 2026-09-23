import 'package:flutter/material.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/cards/facility_card.dart';
import '../../../../../core/widgets/cards/medical_camp_card.dart';
import '../../../../../core/widgets/chips/status_chip.dart';
import '../../domain/facility.dart';

/// Maps a [Facility] onto the shared facility cards with localized labels.
class FacilityTile extends StatelessWidget {
  const FacilityTile({super.key, required this.facility, this.onTap});

  final Facility facility;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = AppFormatters.of(context);
    final distance = facility.distanceMeters == null
        ? null
        : format.distance(facility.distanceMeters);

    if (facility.isCamp) {
      final end = facility.endDateTime;
      return MedicalCampCard(
        name: facility.name,
        typeLabel: l10n.facilityTypeCamp,
        validityLabel: end == null ? '' : l10n.facilityOpenUntil(format.shortDateTime(end)),
        address: facility.address,
        distanceLabel: distance,
        services: facility.services,
        onTap: onTap,
      );
    }

    return FacilityCard(
      name: facility.name,
      typeLabel: l10n.facilityTypeHospital,
      address: facility.address,
      distanceLabel: distance,
      services: facility.services,
      badges: [
        if (facility.hasEmergencyDepartment)
          StatusChip(
            label: l10n.facilityEmergencyDept,
            tone: AppTone.emergency,
            icon: Icons.emergency_rounded,
          ),
      ],
      onTap: onTap,
    );
  }
}
