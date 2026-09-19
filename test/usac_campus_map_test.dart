import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

final Uint8List _transparentPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

class FakeTileProvider extends TileProvider {
  FakeTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(_transparentPng);
  }
}

void main() {
  group('UsacMapTileServers', () {
    test('contains valid tile URLs and subdomains', () {
      expect(UsacMapTileServers.openStreetMap, equals('https://tile.openstreetmap.org/{z}/{x}/{y}.png'));
      expect(UsacMapTileServers.defaultSubdomains, isEmpty);
    });
  });

  group('UsacCampusMap configuration and performance defaults', () {
    test('default performance options are optimized for fast tile loading', () {
      const map = UsacCampusMap();

      expect(map.urlTemplate, equals(UsacMapTileServers.openStreetMap));
      expect(map.subdomains, equals(UsacMapTileServers.defaultSubdomains));
      expect(map.panBuffer, equals(0), reason: 'panBuffer should be 0 to avoid loading offscreen tiles initially');
      expect(map.keepBuffer, equals(2));
      expect(map.minZoom, equals(15.0));
      expect(map.clipToCampus, isTrue);
      expect(map.campusCutoutColor, equals(Colors.white));
      expect(map.tileDisplay, isA<InstantaneousTileDisplay>(), reason: 'tileDisplay should be instantaneous to prevent fade-in lag');
      expect(map.showRecenterCampusButton, isTrue);
      expect(map.showLocationButton, isTrue);
      expect(map.showZoomButtons, isTrue);
      expect(map.enableActiveTracking, isFalse);
      expect(map.mapController, isNull);
    });

    test('accepts custom tile and control configuration options', () {
      final controller = MapController();
      const customUrl = 'https://custom.tiles.org/{z}/{x}/{y}.png';
      const customSubdomains = ['x', 'y'];
      final map = UsacCampusMap(
        urlTemplate: customUrl,
        subdomains: customSubdomains,
        panBuffer: 1,
        keepBuffer: 4,
        mapController: controller,
        showZoomButtons: false,
        showLocationButton: false,
        showRecenterCampusButton: false,
        enableActiveTracking: true,
        clipToCampus: false,
        campusCutoutColor: Colors.black,
      );

      expect(map.urlTemplate, equals(customUrl));
      expect(map.subdomains, equals(customSubdomains));
      expect(map.panBuffer, equals(1));
      expect(map.keepBuffer, equals(4));
      expect(map.mapController, equals(controller));
      expect(map.showZoomButtons, isFalse);
      expect(map.showLocationButton, isFalse);
      expect(map.showRecenterCampusButton, isFalse);
      expect(map.enableActiveTracking, isTrue);
      expect(map.clipToCampus, isFalse);
      expect(map.campusCutoutColor, equals(Colors.black));
    });

    test('UsacCampusBoundary generates valid cutout mask with campus perimeter hole', () {
      final mask = UsacCampusBoundary.createCampusCutoutMask();
      expect(mask.holePointsList, isNotNull);
      expect(mask.holePointsList!.length, equals(1));
      expect(mask.holePointsList!.first.length, equals(UsacCampusBoundary.campusPerimeter.length));
      expect(mask.disableHolesBorder, isFalse);
      expect(mask.borderColor, equals(const Color(0xFF002B49)));
    });

    testWidgets('renders floating interactive action buttons by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UsacCampusMap(
              tileProvider: FakeTileProvider(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byTooltip('Acercar'), findsOneWidget);
      expect(find.byTooltip('Alejar'), findsOneWidget);
      expect(find.byTooltip('Centrar en Campus Central'), findsOneWidget);
      expect(find.byTooltip('Mi ubicacion'), findsOneWidget);
    });

    testWidgets('renders route polyline and navigation card when routeDestination is provided', (tester) async {
      final destination = UsacCampusDataset.allBuildings.first;
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UsacCampusMap(
              tileProvider: FakeTileProvider(),
              routeDestination: destination,
              onClearRoute: () => cleared = true,
              animateCameraTransitions: false,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(PolylineLayer), findsOneWidget);
      expect(find.textContaining('Ruta a'), findsOneWidget);
      expect(find.byTooltip('Cancelar ruta'), findsOneWidget);

      await tester.tap(find.byTooltip('Cancelar ruta'));
      expect(cleared, isTrue);
    });

    testWidgets('renders route polyline and navigation card when activeRoute is provided directly', (tester) async {
      final destination = UsacCampusDataset.allBuildings.first;
      const origin = LatLng(14.587500, -90.551845);
      final route = CampusRoute(
        origin: origin,
        destination: destination,
        points: const [origin, LatLng(14.588000, -90.552500), LatLng(14.588576, -90.553156)],
        distanceInMeters: 250.0,
        estimatedDuration: const Duration(minutes: 3),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UsacCampusMap(
              tileProvider: FakeTileProvider(),
              activeRoute: route,
              animateCameraTransitions: false,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(PolylineLayer), findsOneWidget);
      expect(find.textContaining('Ruta a'), findsOneWidget);
      expect(find.textContaining('250 m'), findsOneWidget);
      expect(find.textContaining('3 min a pie'), findsOneWidget);
    });
  });
}
