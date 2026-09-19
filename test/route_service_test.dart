import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  group('CampusRouteService', () {
    final routeService = CampusRouteService();

    test('calculates direct route for close proximity destinations', () {
      const origin = LatLng(14.587794, -90.553240);
      final destination = UsacCampusDataset.allBuildings.firstWhere(
        (b) => b.id == 't-3',
      );

      final route = routeService.calculateRoute(
        origin: origin,
        destination: destination,
      );

      expect(route.origin, equals(origin));
      expect(route.destination.id, equals('t-3'));
      expect(route.points.length, equals(2));
      expect(route.distanceInMeters, lessThan(5.0));
      expect(route.estimatedDuration, equals(Duration.zero));
    });

    test('calculates walkway path for separated buildings across campus', () {
      const origin = LatLng(14.583924, -90.555003);
      final destination = UsacCampusDataset.allBuildings.firstWhere(
        (b) => b.id == 'm-1',
      );

      final route = routeService.calculateRoute(
        origin: origin,
        destination: destination,
      );

      expect(route.points.length, greaterThanOrEqualTo(3));
      expect(route.points.first, equals(origin));
      expect(route.points.last, equals(destination.location));
      expect(route.distanceInMeters, greaterThan(600.0));
      expect(route.estimatedDuration.inMinutes, greaterThan(5));
    });

    test('calculates route to arbitrary coordinates within campus', () {
      const origin = LatLng(14.588146, -90.551704);
      const targetCoords = LatLng(14.586838, -90.551859);

      final route = routeService.calculateRouteToCoordinates(
        origin: origin,
        destinationCoords: targetCoords,
        destinationName: 'Biblioteca Central',
      );

      expect(route.points.isNotEmpty, isTrue);
      expect(route.points.first, equals(origin));
      expect(route.points.last, equals(targetCoords));
    });
  });
}
