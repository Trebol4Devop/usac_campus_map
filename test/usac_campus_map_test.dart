import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

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
    });

    testWidgets('renders floating interactive action buttons by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UsacCampusMap(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byTooltip('Acercar'), findsOneWidget);
      expect(find.byTooltip('Alejar'), findsOneWidget);
      expect(find.byTooltip('Centrar en Campus Central'), findsOneWidget);
      expect(find.byTooltip('Mi ubicacion'), findsOneWidget);
    });
  });
}
