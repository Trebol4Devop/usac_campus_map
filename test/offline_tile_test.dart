import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TileCoordinates and Slippy Map calculations', () {
    test('Converts USAC central coordinates to slippy map tile index at zoom 16', () {
      final tile = TileIndex.fromLatLng(
        latitude: 14.5865,
        longitude: -90.5512,
        zoom: 16,
      );

      expect(tile.z, equals(16));
      expect(tile.x, isPositive);
      expect(tile.y, isPositive);
    });

    test('Converts tile index back to LatLng coordinates with acceptable precision', () {
      const originalLat = 14.5865;
      const originalLng = -90.5512;
      const zoom = 16;

      final tile = TileIndex.fromLatLng(
        latitude: originalLat,
        longitude: originalLng,
        zoom: zoom,
      );

      final reconstructed = TileIndex.toLatLng(tile);
      expect((reconstructed.latitude - originalLat).abs(), lessThan(0.01));
      expect((reconstructed.longitude - originalLng).abs(), lessThan(0.01));
    });

    test('Retrieves correct range of tiles in campus bounding box', () {
      final tiles = TileIndex.getTilesInBounds(
        minLat: 14.5850,
        minLng: -90.5530,
        maxLat: 14.5880,
        maxLng: -90.5490,
        zoom: 16,
      );

      expect(tiles.isNotEmpty, isTrue);
      for (final t in tiles) {
        expect(t.z, equals(16));
      }
    });

    test('TileIndex equality and string representation', () {
      const t1 = TileIndex(z: 15, x: 100, y: 200);
      const t2 = TileIndex(z: 15, x: 100, y: 200);
      const t3 = TileIndex(z: 15, x: 101, y: 200);

      expect(t1, equals(t2));
      expect(t1.hashCode, equals(t2.hashCode));
      expect(t1, isNot(equals(t3)));
      expect(t1.toString(), contains('TileIndex(z: 15, x: 100, y: 200)'));
    });
  });

  group('OfflineTilePackage metadata and bounds verification', () {
    test('Default USAC campus package contains expected bounding box and zoom limits', () {
      final package = OfflineTilePackage.usacCampusDefault();

      expect(package.id, equals('usac-campus-central-offline'));
      expect(package.minZoom, equals(14));
      expect(package.maxZoom, equals(18));
      expect(package.totalTiles, isPositive);
      expect(package.sizeBytes, isPositive);
      expect(package.containsCoordinate(14.5865, -90.5512), isTrue);
      expect(package.containsCoordinate(0.0, 0.0), isFalse);
    });

    test('Package verifies tile containment correctly', () {
      final package = OfflineTilePackage.usacCampusDefault();
      final insideTile = TileIndex.fromLatLng(
        latitude: 14.5865,
        longitude: -90.5512,
        zoom: 16,
      );
      const outsideTile = TileIndex(z: 16, x: 0, y: 0);

      expect(package.containsTile(insideTile), isTrue);
      expect(package.containsTile(outsideTile), isFalse);
    });

    test('Serialization to and from JSON', () {
      final original = OfflineTilePackage.usacCampusDefault();
      final json = original.toJson();
      final recovered = OfflineTilePackage.fromJson(json);

      expect(recovered.id, equals(original.id));
      expect(recovered.name, equals(original.name));
      expect(recovered.minZoom, equals(original.minZoom));
      expect(recovered.maxZoom, equals(original.maxZoom));
      expect(recovered.totalTiles, equals(original.totalTiles));
    });
  });

  group('CampusOfflineTileProvider', () {
    test('Provides memory transparent image when tile is outside package boundaries', () {
      final package = OfflineTilePackage.usacCampusDefault();
      final provider = CampusOfflineTileProvider(package: package);

      const outOfBoundsCoords = TileCoordinates(0, 0, 16);
      final options = TileLayer();

      final image = provider.getImage(outOfBoundsCoords, options);
      expect(image, isA<MemoryImage>());
    });

    test('Uses custom loader if provided', () {
      var customLoaderCalled = false;
      final provider = CampusOfflineTileProvider(
        customLoader: (coordinates, options) {
          customLoaderCalled = true;
          return MemoryImage(TileProvider.transparentImage);
        },
      );

      provider.getImage(const TileCoordinates(10, 10, 15), TileLayer());
      expect(customLoaderCalled, isTrue);
    });
  });
}
