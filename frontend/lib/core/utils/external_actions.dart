import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/models/geo_point.dart';

/// Phone calls and turn-by-turn directions in other apps.
class ExternalActions {
  const ExternalActions();

  static const emergencyNumber = '112';

  Future<bool> call(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return launchUrl(Uri(scheme: 'tel', path: digits));
  }

  Future<bool> callEmergency() => call(emergencyNumber);

  /// Opens the device's map app, falling back to OpenStreetMap in a browser.
  Future<bool> directionsTo(GeoPoint point) async {
    final lat = point.latitude;
    final lng = point.longitude;
    final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    try {
      if (await launchUrl(geo, mode: LaunchMode.externalApplication)) return true;
    } catch (_) {
      // No app handles geo: URIs; use the web fallback.
    }
    return launchUrl(
      Uri.https('www.openstreetmap.org', '/directions', {'to': '$lat,$lng'}),
      mode: LaunchMode.externalApplication,
    );
  }
}

final externalActionsProvider = Provider<ExternalActions>((ref) => const ExternalActions());
