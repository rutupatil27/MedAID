import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../chips/status_chip.dart';
import 'app_card.dart';

/// Hospital or medical facility summary. Camps use [MedicalCampCard], which
/// builds on this card.
class FacilityCard extends StatelessWidget {
  const FacilityCard({
    super.key,
    required this.name,
    required this.typeLabel,
    this.icon = Icons.local_hospital_rounded,
    this.tone = AppTone.info,
    this.address,
    this.distanceLabel,
    this.services = const [],
    this.footer,
    this.badges = const [],
    this.onTap,
  });

  final String name;
  final String typeLabel;
  final IconData icon;
  final AppTone tone;
  final String? address;
  final String? distanceLabel;
  final List<String> services;

  /// Extra line under the services, e.g. a camp's validity period.
  final Widget? footer;
  final List<Widget> badges;
  final VoidCallback? onTap;

  static const _maxServices = 3;

  @override
  Widget build(BuildContext context) {
    final colors = context.palette.tone(tone);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppSizes.avatarMd,
                height: AppSizes.avatarMd,
                decoration: BoxDecoration(color: colors.background, borderRadius: AppRadii.mdAll),
                child: Icon(icon, color: colors.foreground),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(typeLabel, style: context.textStyles.bodySmall),
                  ],
                ),
              ),
              if (distanceLabel != null) ...[
                const SizedBox(width: AppSpacing.sm),
                StatusChip(label: distanceLabel!, icon: Icons.near_me_rounded),
              ],
            ],
          ),
          if (address != null && address!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_outlined, size: AppSizes.iconSm, color: context.palette.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    address!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          if (services.isNotEmpty || badges.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ...badges,
                for (final service in services.take(_maxServices)) StatusChip(label: service),
                if (services.length > _maxServices)
                  StatusChip(label: '+${services.length - _maxServices}'),
              ],
            ),
          ],
          if (footer != null) ...[const SizedBox(height: AppSpacing.md), footer!],
        ],
      ),
    );
  }
}
