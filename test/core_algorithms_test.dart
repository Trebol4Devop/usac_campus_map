import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  group('PriorityQueue tests', () {
    test('enqueues and dequeues elements in ascending priority order', () {
      final pq = PriorityQueue<String>();
      expect(pq.isEmpty, isTrue);

      pq.enqueue('C', 30.0);
      pq.enqueue('A', 10.0);
      pq.enqueue('B', 20.0);
      pq.enqueue('Z', 5.0);

      expect(pq.length, equals(4));
      expect(pq.peek(), equals('Z'));
      expect(pq.dequeue(), equals('Z'));
      expect(pq.dequeue(), equals('A'));
      expect(pq.dequeue(), equals('B'));
      expect(pq.dequeue(), equals('C'));
      expect(pq.isEmpty, isTrue);
    });

    test('throws StateError when dequeueing or peeking on empty queue', () {
      final pq = PriorityQueue<int>();
      expect(() => pq.dequeue(), throwsStateError);
      expect(() => pq.peek(), throwsStateError);
    });
  });

  group('DistanceCalculator tests', () {
    test('haversineDistance calculates accurate distances in meters', () {
      const p1 = LatLng(14.587500, -90.551845);
      const p2 = LatLng(14.587500, -90.551845);
      expect(DistanceCalculator.haversineDistance(p1, p2), equals(0.0));

      const p3 = LatLng(14.588500, -90.551845);
      final dist = DistanceCalculator.haversineDistance(p1, p3);
      expect(dist, greaterThan(100.0));
      expect(dist, lessThan(125.0));
    });

    test('calculateBearing returns valid angles 0..360', () {
      const p1 = LatLng(14.580000, -90.550000);
      const pNorth = LatLng(14.590000, -90.550000);
      final bearing = DistanceCalculator.calculateBearing(p1, pNorth);
      expect(bearing, closeTo(0.0, 1.0));
    });

    test('isPointInPolygon detects inside and outside points', () {
      final square = [
        const LatLng(14.0, -90.0),
        const LatLng(14.0, -89.0),
        const LatLng(13.0, -89.0),
        const LatLng(13.0, -90.0),
      ];

      expect(DistanceCalculator.isPointInPolygon(const LatLng(13.5, -89.5), square), isTrue);
      expect(DistanceCalculator.isPointInPolygon(const LatLng(15.0, -89.5), square), isFalse);
    });
  });

  group('SnapToPath tests', () {
    test('snaps coordinate within 10m to path segment', () {
      const segStart = LatLng(14.587000, -90.550000);
      const segEnd = LatLng(14.587000, -90.551000);
      const segment = PathSegment(start: segStart, end: segEnd);

      const nearbyGps = LatLng(14.587030, -90.550500);
      final result = SnapToPath.snapPoint(nearbyGps, [segment]);

      expect(result.isSnapped, isTrue);
      expect(result.distanceMeters, lessThan(10.0));
      expect(result.point.latitude, closeTo(14.587000, 0.00001));
    });

    test('does not snap if point is beyond maxRadiusMeters', () {
      const segStart = LatLng(14.587000, -90.550000);
      const segEnd = LatLng(14.587000, -90.551000);
      const segment = PathSegment(start: segStart, end: segEnd);

      const farGps = LatLng(14.589000, -90.550500);
      final result = SnapToPath.snapPoint(farGps, [segment]);

      expect(result.isSnapped, isFalse);
      expect(result.point, equals(farGps));
    });
  });

  group('AStar routing tests', () {
    test('calculates shortest path and respects navigation modes', () {
      final nodes = {
        'n1': const CampusNode(id: 'n1', location: LatLng(14.5870, -90.5530)),
        'n2': const CampusNode(id: 'n2', location: LatLng(14.5872, -90.5530)),
        'n3': const CampusNode(id: 'n3', location: LatLng(14.5874, -90.5530)),
        'n4': const CampusNode(id: 'n4', location: LatLng(14.5872, -90.5528)),
      };

      final edges = {
        'n1': [
          const CampusEdge(source: 'n1', target: 'n2', weight: 20.0, type: 'stairs'),
          const CampusEdge(source: 'n1', target: 'n4', weight: 25.0, type: 'covered'),
        ],
        'n2': [
          const CampusEdge(source: 'n2', target: 'n3', weight: 20.0, type: 'walkway'),
        ],
        'n4': [
          const CampusEdge(source: 'n4', target: 'n3', weight: 25.0, type: 'covered'),
        ],
      };

      final aStar = AStar(nodes: nodes, adjacencyList: edges);

      final pedRoute = aStar.findShortestPath(
        startNodeId: 'n1',
        targetNodeIds: {'n3'},
        mode: NavigationMode.pedestrian,
      );
      expect(pedRoute, isNotNull);
      expect(pedRoute!.nodes.first.id, equals('n1'));
      expect(pedRoute.nodes.last.id, equals('n3'));

      final accRoute = aStar.findShortestPath(
        startNodeId: 'n1',
        targetNodeIds: {'n3'},
        mode: NavigationMode.accessible,
      );
      expect(accRoute, isNotNull);
      expect(accRoute!.edges.any((e) => e.type == 'stairs'), isFalse);
      expect(accRoute.nodes.map((n) => n.id).toList(), equals(['n1', 'n4', 'n3']));

      final covRoute = aStar.findShortestPath(
        startNodeId: 'n1',
        targetNodeIds: {'n3'},
        mode: NavigationMode.covered,
      );
      expect(covRoute, isNotNull);
      expect(covRoute!.nodes.map((n) => n.id).toList(), equals(['n1', 'n4', 'n3']));
    });
  });
}
