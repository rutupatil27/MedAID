import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_config.dart';
import '../../theme/app_theme.dart';
import 'map_marker.dart';

/// OpenStreetMap view (D-002). Screens pass markers and an optional route;
/// no screen talks to flutter_map directly, so the map provider stays replaceable.
class LocationMap extends StatelessWidget {
  const LocationMap({
    super.key,
    required this.center,
    this.markers = const [],
    this.route = const [],
    this.zoom = 15,
    this.fitToContent = false,
    this.interactive = true,
    this.controller,
    this.onMarkerTap,
    this.onTap,
    this.tileProvider,
  });

  final LatLng center;
  final List<MapMarkerData> markers;

  /// Road route polyline (from the backend routing endpoint).
  final List<LatLng> route;
  final double zoom;

  /// Fits the camera to all markers and the route.
  final bool fitToContent;
  final bool interactive;
  final MapController? controller;
  final ValueChanged<MapMarkerData>? onMarkerTap;

  /// Tap on the map itself (e.g. to place a camp).
  final ValueChanged<LatLng>? onTap;

  /// Injectable for tests; defaults to network tiles.
  final TileProvider? tileProvider;

  // Legal attribution required by the OpenStreetMap tile usage policy.
  static const _attribution = '© OpenStreetMap contributors';
  static final _copyrightUrl = Uri.parse('https://www.openstreetmap.org/copyright');

  @override
  Widget build(BuildContext context) {
    final points = [...markers.map((m) => m.point), ...route];
    final canFit = fitToContent && points.length > 1;

    return ClipRRect(
      borderRadius: AppRadii.lgAll,
      child: FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: center,
          initialZoom: zoom,
          minZoom: 3,
          maxZoom: 19,
          initialCameraFit: canFit
              ? CameraFit.coordinates(
                  coordinates: points,
                  padding: const EdgeInsets.all(AppSpacing.huge),
                  maxZoom: 17,
                )
              : null,
          onTap: onTap == null ? null : (_, point) => onTap!(point),
          interactionOptions: InteractionOptions(
            flags: interactive
                ? InteractiveFlag.all & ~InteractiveFlag.rotate
                : InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: AppConfig.mapTileUrl,
            userAgentPackageName: AppConfig.mapUserAgentPackageName,
            tileProvider: tileProvider,
          ),
          if (route.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: route,
                  strokeWidth: 5,
                  color: context.colors.primary,
                  borderStrokeWidth: 2,
                  borderColor: context.colors.surface,
                ),
              ],
            ),
          MarkerLayer(
            markers: [
              for (final marker in markers)
                Marker(
                  point: marker.point,
                  width: MapMarker.size,
                  height: MapMarker.size,
                  child: GestureDetector(
                    onTap: onMarkerTap == null ? null : () => onMarkerTap!(marker),
                    child: MapMarker(data: marker),
                  ),
                ),
            ],
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Material(
                color: context.colors.surface.withValues(alpha: 0.85),
                borderRadius: AppRadii.smAll,
                child: InkWell(
                  borderRadius: AppRadii.smAll,
                  onTap: () => launchUrl(_copyrightUrl, mode: LaunchMode.externalApplication),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    child: Text(
                      _attribution,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.labelSmall,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
