import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:medaid/core/widgets/map/location_map.dart';
import 'package:medaid/core/widgets/map/map_marker.dart';

import '../../helpers/test_app.dart';

/// 1x1 transparent PNG so tests never touch the tile server.
final _transparentPng = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44, //
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F, //
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00, //
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _NoNetworkTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_transparentPng);
}

void main() {
  testWidgets('renders markers, reports marker taps and shows OSM attribution', (tester) async {
    MapMarkerData? tapped;
    const center = LatLng(20.0086, 73.7925);
    final markers = [
      const MapMarkerData(id: 'me', point: center, kind: MapMarkerKind.currentLocation),
      const MapMarkerData(
        id: 'h1',
        point: LatLng(20.0100, 73.7900),
        kind: MapMarkerKind.hospital,
        label: 'Hospital',
      ),
    ];

    await pumpThemed(
      tester,
      SizedBox(
        height: 300,
        child: LocationMap(
          center: center,
          markers: markers,
          tileProvider: _NoNetworkTiles(),
          onMarkerTap: (m) => tapped = m,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(MapMarker), findsNWidgets(2));
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.local_hospital_rounded));
    expect(tapped?.id, 'h1');
  });
}
