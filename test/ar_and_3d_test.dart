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

  group('Building3DModel geometric construction', () {
    test('Constructs 3D volumetric model from CampusBuilding', () {
      const building = CampusBuilding(
        id: 'b-t3',
        name: 'Edificio T-3',
        code: 'T-3',
        category: 'faculty',
        center: userPos,
        polygon: [
          LatLng(14.5860, -90.5520),
          LatLng(14.5862, -90.5520),
          LatLng(14.5862, -90.5518),
          LatLng(14.5860, -90.5518),
        ],
        floorsCount: 3,
      );

      final model = Building3DModel.fromBuilding(building, floorHeightMeters: 3.5);

      expect(model.buildingId, equals('b-t3'));
      expect(model.floors, equals(3));
      expect(model.heightMeters, equals(10.5));
      expect(model.wallFaces.length, equals(4));
      expect(model.roofFace.vertices.length, equals(4));
      expect(model.baseFace.vertices.length, equals(4));
    });

    test('Projects 3D vertices to isometric screen coordinates without error', () {
      const v = Vector3D(10.0, 10.0, 5.0);
      final offset = v.toIsometric(rotationAngle: 45.0, tiltAngle: 30.0, scale: 2.0);

      expect(offset.dx.isFinite, isTrue);
      expect(offset.dy.isFinite, isTrue);
    });
  });

  group('AR and 3D Widgets Rendering', () {
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

    testWidgets('Building3DViewer mounts and paints 3D building canvas', (tester) async {
      const building = CampusBuilding(
        id: 'b-t3',
        name: 'Edificio T-3',
        code: 'T-3',
        category: 'faculty',
        center: userPos,
        polygon: [
          LatLng(14.5860, -90.5520),
          LatLng(14.5862, -90.5520),
          LatLng(14.5862, -90.5518),
          LatLng(14.5860, -90.5518),
        ],
        floorsCount: 3,
      );

      final model = Building3DModel.fromBuilding(building);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300.0,
              height: 300.0,
              child: Building3DViewer(model: model),
            ),
          ),
        ),
      );

      expect(find.text('Edificio T-3'), findsOneWidget);
      expect(find.text('3 niveles • 10.5 m de altura'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
