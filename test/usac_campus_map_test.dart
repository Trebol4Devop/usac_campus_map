import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  group('UsacMapTileServers', () {
    test('contains valid tile URLs and subdomains', () {
      expect(UsacMapTileServers.openStreetMap, contains('{s}.tile.openstreetmap.org'));
      expect(UsacMapTileServers.defaultSubdomains, equals(['a', 'b', 'c']));
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
      expect(map.tileProvider, isNull);
    });

    test('accepts custom tile configuration options', () {
      const customUrl = 'https://custom.tiles.org/{z}/{x}/{y}.png';
      const customSubdomains = ['x', 'y'];
      const map = UsacCampusMap(
        urlTemplate: customUrl,
        subdomains: customSubdomains,
        panBuffer: 1,
        keepBuffer: 4,
      );

      expect(map.urlTemplate, equals(customUrl));
      expect(map.subdomains, equals(customSubdomains));
      expect(map.panBuffer, equals(1));
      expect(map.keepBuffer, equals(4));
    });
  });
}
