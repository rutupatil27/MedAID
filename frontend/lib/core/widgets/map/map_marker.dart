import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/app_theme.dart';

enum MapMarkerKind { currentLocation, hospital, camp, emergency, volunteer }

/// Provider-independent marker description consumed by [LocationMap].
class MapMarkerData {
  const MapMarkerData({
    required this.id,
    required this.point,
    required this.kind,
    this.label,
    this.selected = false,
    this.tone,
  });

  final String id;
  final LatLng point;
  final MapMarkerKind kind;
  final String? label;
  final bool selected;

  /// Overrides the kind colour, e.g. to show a volunteer's state.
  final AppTone? tone;
}

/// Pin visual for a [MapMarkerData], coloured by kind from the global theme.
class MapMarker extends StatelessWidget {
  const MapMarker({super.key, required this.data});

  final MapMarkerData data;

  static const double size = 44;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (Color kindColor, IconData icon) = switch (data.kind) {
      MapMarkerKind.currentLocation => (context.colors.primary, Icons.my_location_rounded),
      MapMarkerKind.hospital => (palette.info, Icons.local_hospital_rounded),
      MapMarkerKind.camp => (palette.success, Icons.medical_services_rounded),
      MapMarkerKind.emergency => (palette.emergency, Icons.emergency_rounded),
      MapMarkerKind.volunteer => (context.colors.secondary, Icons.volunteer_activism_rounded),
    };
    final tone = data.tone;
    final color = tone == null ? kindColor : palette.tone(tone).foreground;
    final scale = data.selected ? 1.2 : 1.0;

    return Semantics(
      label: data.label,
      child: AnimatedScale(
        scale: scale,
        duration: AppDurations.fast,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: context.colors.surface, width: 3),
            boxShadow: AppShadows.card,
          ),
          child: Icon(icon, color: context.colors.onPrimary, size: AppSizes.iconMd),
        ),
      ),
    );
  }
}
