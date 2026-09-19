import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  group('CampusDistanceService', () {
    final distanceService = CampusDistanceService();

    test('calculates accurate Haversine distance between two points', () {
      const p1 = LatLng(14.588146, -90.551704);
      const p2 = LatLng(14.586838, -90.551859);
      final distance = distanceService.calculateDistance(p1, p2);

      expect(distance, greaterThan(140.0));
      expect(distance, lessThan(160.0));
    });

    test('formats distance correctly in meters and kilometers', () {
      expect(distanceService.formatDistance(45.2), equals('45 m'));
      expect(distanceService.formatDistance(750.0), equals('750 m'));
      expect(distanceService.formatDistance(1250.0), equals('1.3 km'));
    });

    test('estimates walking duration based on standard walking speed', () {
      final duration = distanceService.estimateWalkingDuration(120.0);
      expect(duration.inSeconds, equals(100));
      expect(distanceService.formatWalkingTime(duration), equals('1 min'));

      final shortDuration = distanceService.estimateWalkingDuration(30.0);
      expect(distanceService.formatWalkingTime(shortDuration), equals('< 1 min'));
    });

    test('ranks buildings by proximity in ascending order', () {
      const from = LatLng(14.588146, -90.551704);
      final ranked = distanceService.rankBuildingsByProximity(from: from);

      expect(ranked.isNotEmpty, isTrue);
      expect(ranked.first.building.id, equals('rectoria'));
      expect(ranked.first.distanceInMeters, lessThan(5.0));

      for (int i = 0; i < ranked.length - 1; i++) {
        expect(
          ranked[i].distanceInMeters,
          lessThanOrEqualTo(ranked[i + 1].distanceInMeters),
        );
      }
    });
  });
}
