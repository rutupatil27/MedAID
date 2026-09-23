import 'package:flutter/material.dart';

import '../../../../../app/localization/generated/app_localizations.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/cards/emergency_card.dart';
import '../../../../../shared/enums/emergency_status.dart';
import '../../../../../shared/models/emergency.dart';

/// Emergency summary for monitoring: reporter, responder and attempts.
class AdminEmergencyCard extends StatelessWidget {
  const AdminEmergencyCard({super.key, required this.emergency, this.onTap});

  final Emergency emergency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = AppFormatters.of(context);
    final volunteer = emergency.assignedVolunteer;

    return EmergencyCard(
      title: emergency.alertNumber,
      subtitle: emergency.reporter?.name,
      statusLabel: emergency.status.label(l10n),
      statusTone: emergency.status.tone,
      timeLabel: format.relativeTime(emergency.createdAt),
      highlight: emergency.status == EmergencyStatus.unassigned,
      details: [
        (icon: Icons.volunteer_activism_rounded, text: volunteer?.name ?? l10n.adminNotAssigned),
        if (emergency.attemptCount > 0)
          (icon: Icons.replay_rounded, text: l10n.adminAttempts(emergency.attemptCount)),
      ],
      onTap: onTap,
    );
  }
}
