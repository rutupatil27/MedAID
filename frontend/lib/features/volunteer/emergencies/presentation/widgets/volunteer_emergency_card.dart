import 'package:flutter/material.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/cards/emergency_card.dart';
import '../../../../../core/widgets/misc/countdown_text.dart';
import '../../../../../shared/enums/volunteer_enums.dart';
import '../../../../../shared/models/emergency.dart';

/// A dispatched emergency from the volunteer's point of view.
class VolunteerEmergencyCard extends StatelessWidget {
  const VolunteerEmergencyCard({super.key, required this.emergency, this.onTap});

  final Emergency emergency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = AppFormatters.of(context);
    final assignment = emergency.assignment;
    final pending = assignment?.status == AssignmentStatus.pending;
    final distance = assignment?.routeDistanceMeters;

    return EmergencyCard(
      title: emergency.alertNumber,
      subtitle: emergency.reporter?.name,
      statusLabel: assignment?.status.label(l10n) ?? emergency.status.label(l10n),
      statusTone: assignment?.status.tone ?? emergency.status.tone,
      timeLabel: format.relativeTime(assignment?.dispatchedAt ?? emergency.createdAt),
      highlight: pending,
      details: [
        if (distance != null) (icon: Icons.near_me_rounded, text: format.distance(distance)),
      ],
      trailing: pending
          ? CountdownText(
              until: assignment!.expiresAt,
              builder: l10n.volunteerRespondWithin,
              style: context.textStyles.labelLarge?.copyWith(color: context.palette.emergency),
            )
          : null,
      onTap: onTap,
    );
  }
}
