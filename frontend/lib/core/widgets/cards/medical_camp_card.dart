import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'facility_card.dart';

/// Temporary medical camp summary: a [FacilityCard] with the validity period.
class MedicalCampCard extends StatelessWidget {
  const MedicalCampCard({
    super.key,
    required this.name,
    required this.typeLabel,
    required this.validityLabel,
    this.address,
    this.distanceLabel,
    this.services = const [],
    this.badges = const [],
    this.onTap,
  });

  final String name;
  final String typeLabel;

  /// e.g. "Open until 18 Sep, 8:00 PM".
  final String validityLabel;
  final String? address;
  final String? distanceLabel;
  final List<String> services;
  final List<Widget> badges;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FacilityCard(
      name: name,
      typeLabel: typeLabel,
      icon: Icons.medical_services_rounded,
      tone: AppTone.success,
      address: address,
      distanceLabel: distanceLabel,
      services: services,
      badges: badges,
      onTap: onTap,
      footer: Row(
        children: [
          Icon(Icons.schedule_rounded, size: AppSizes.iconSm, color: context.palette.success),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              validityLabel,
              style: context.textStyles.labelMedium?.copyWith(color: context.palette.success),
            ),
          ),
        ],
      ),
    );
  }
}
