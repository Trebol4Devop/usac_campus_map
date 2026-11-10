import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const userPos = LatLng(14.5860, -90.5520);
  const targetInFront = LatLng(14.5870, -90.5520);
  const targetBehind = LatLng(14.5850, -90.5520);

  group('ArProjectionEngine calculations', () {
    const engine = ArProjectionEngine(horizontalFov: 60.0, verticalFov: 45.0);

    test('Projects waypoint directly ahead within field of view', () {
      const waypoint = ArWaypoint(
        id: 't3',
        title: 'Edificio T-3',
        location: targetInFront,
      );

      final result = engine.projectWaypoint(
        userLocation: userPos,
        deviceHeading: 0.0,
        waypoint: waypoint,
      );

      expect(result.distanceMeters, isPositive);
      expect(result.relativeAzimuth.abs(), lessThan(5.0));
      expect(result.isVisibleInFov, isTrue);
      expect(result.screenPosition.dx, closeTo(180.0, 15.0));
    });

    test('Identifies waypoint behind user as outside field of view', () {
      const waypoint = ArWaypoint(
        id: 's12',
        title: 'Edificio S-12',
        location: targetBehind,
      );

      final result = engine.projectWaypoint(
        userLocation: userPos,
        deviceHeading: 0.0,
        waypoint: waypoint,
      );

      expect(result.isVisibleInFov, isFalse);
      expect(result.relativeAzimuth.abs(), greaterThan(90.0));
    });

    test('Projects multiple waypoints and sorts them by distance', () {
      final waypoints = [
        const ArWaypoint(id: 'w1', title: 'Lejano', location: LatLng(14.5900, -90.5520)),
        const ArWaypoint(id: 'w2', title: 'Cercano', location: LatLng(14.5865, -90.5520)),
      ];

      final results = engine.projectWaypoints(
        userLocation: userPos,
        deviceHeading: 0.0,
        waypoints: waypoints,
      );

      expect(results.length, equals(2));
      expect(results.first.waypoint.id, equals('w2'));
      expect(results.last.waypoint.id, equals('w1'));
    });
  });

  group('AR Wayfinding Widgets Rendering', () {
    testWidgets('ArWayfindingView mounts and renders projection overlays', (tester) async {
      const waypoint = ArWaypoint(
        id: 't3',
        title: 'Edificio T-3',
        location: targetInFront,
      );

      const inFovResult = ArProjectionResult(
        waypoint: waypoint,
        distanceMeters: 110.0,
        targetBearing: 0.0,
        relativeAzimuth: 0.0,
        relativePitch: 0.0,
        screenPosition: Offset(180.0, 320.0),
        isVisibleInFov: true,
        indicatorAngle: 0.0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360.0,
              height: 640.0,
              child: ArWayfindingView(
                projections: [inFovResult],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Edificio T-3'), findsOneWidget);
      expect(find.text('110 m'), findsOneWidget);
    });
  });
}
