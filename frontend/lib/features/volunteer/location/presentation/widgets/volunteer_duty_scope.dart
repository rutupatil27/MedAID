import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/assignment_alerts.dart';
import '../../../application/location_tracking_controller.dart';

/// Keeps the work a volunteer on duty depends on running for as long as the
/// volunteer area is on screen: sharing live location, and alerting them with
/// a system notification when an emergency arrives.
class VolunteerDutyScope extends ConsumerWidget {
  const VolunteerDutyScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
      ..watch(locationTrackingProvider.select((state) => state.status))
      ..watch(assignmentAlertsProvider);
    return child;
  }
}
