import 'package:flutter/material.dart' hide NavigationMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const buildingA = CampusBuilding(
    id: 't-3',
    name: 'Edificio T-3',
    code: 'T-3',
    category: 'faculty',
    center: LatLng(14.5865, -90.5520),
    polygon: [
      LatLng(14.5864, -90.5521),
      LatLng(14.5866, -90.5521),
      LatLng(14.5866, -90.5519),
      LatLng(14.5864, -90.5519),
    ],
    floorsCount: 3,
  );

  const buildingB = CampusBuilding(
    id: 'biblio-central',
    name: 'Biblioteca Central',
    code: 'BIBLIO',
    category: 'library',
    center: LatLng(14.5880, -90.5520),
    polygon: [
      LatLng(14.5879, -90.5521),
      LatLng(14.5881, -90.5521),
      LatLng(14.5881, -90.5519),
      LatLng(14.5879, -90.5519),
    ],
    floorsCount: 4,
  );

  const testRoute = CampusRoute(
    points: [
      LatLng(14.5865, -90.5520),
      LatLng(14.5870, -90.5520),
      LatLng(14.5875, -90.5520),
      LatLng(14.5880, -90.5520),
    ],
    totalDistance: 165.0,
    estimatedTimeMinutes: 2.3,
    mode: NavigationMode.pedestrian,
    steps: [
      RouteStep(
        instruction: 'Camina hacia el norte desde Edificio T-3',
        distance: 55.0,
        location: LatLng(14.5865, -90.5520),
        type: 'walk',
      ),
      RouteStep(
        instruction: 'Continua recto por la plaza central',
        distance: 55.0,
        location: LatLng(14.5870, -90.5520),
        type: 'walk',
      ),
      RouteStep(
        instruction: 'Llegada a Biblioteca Central',
        distance: 55.0,
        location: LatLng(14.5880, -90.5520),
        type: 'arrive',
      ),
    ],
    nodes: [
      CampusNode(id: 'n1', location: LatLng(14.5865, -90.5520)),
      CampusNode(id: 'n2', location: LatLng(14.5870, -90.5520)),
      CampusNode(id: 'n3', location: LatLng(14.5875, -90.5520)),
      CampusNode(id: 'n4', location: LatLng(14.5880, -90.5520)),
    ],
    edges: [
      CampusEdge(source: 'n1', target: 'n2', weight: 55.0, type: 'standard'),
      CampusEdge(source: 'n2', target: 'n3', weight: 55.0, type: 'standard'),
      CampusEdge(source: 'n3', target: 'n4', weight: 55.0, type: 'standard'),
    ],
  );

  group('UsacCampusMapController 3D Mode & Walking View State', () {
    test('Toggles 3D mode correctly', () {
      final controller = UsacCampusMapController();
      expect(controller.is3DMode, isFalse);

      controller.toggle3DMode();
      expect(controller.is3DMode, isTrue);

      controller.set3DMode(false);
      expect(controller.is3DMode, isFalse);

      controller.dispose();
    });

    test('Toggles 3D walking view correctly', () {
      final controller = UsacCampusMapController();
      expect(controller.is3DWalkingViewOpen, isFalse);

      controller.open3DWalkingView();
      expect(controller.is3DWalkingViewOpen, isTrue);

      controller.close3DWalkingView();
      expect(controller.is3DWalkingViewOpen, isFalse);

      controller.toggle3DWalkingView();
      expect(controller.is3DWalkingViewOpen, isTrue);

      controller.dispose();
    });

    test('Follows user heading state is configurable', () {
      final controller = UsacCampusMapController();
      expect(controller.followUserHeading, isFalse);

      controller.setFollowUserHeading(true);
      expect(controller.followUserHeading, isTrue);

      controller.dispose();
    });
  });

  group('CampusWalk3DView Widget', () {
    testWidgets('Renders 3D walking view and displays navigation banner', (tester) async {
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: CampusWalk3DView(
            route: testRoute,
            buildings: const [buildingA, buildingB],
            initialLocation: testRoute.points.first,
            initialHeading: 0.0,
            onClose: () => closed = true,
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(CampusWalk3DView), findsOneWidget);
      expect(find.textContaining('Camina hacia el norte'), findsOneWidget);
      expect(find.textContaining('restantes'), findsOneWidget);
      expect(find.byIcon(Icons.directions_walk), findsWidgets);
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(closed, isTrue);
    });

    testWidgets('Advances along route when simulation button is tapped', (tester) async {
      LatLng? updatedLocation;

      await tester.pumpWidget(
        MaterialApp(
          home: CampusWalk3DView(
            route: testRoute,
            buildings: const [buildingA, buildingB],
            initialLocation: testRoute.points.first,
            initialHeading: 0.0,
            onLocationChanged: (loc) => updatedLocation = loc,
          ),
        ),
      );

      await tester.pump();

      final advanceButton = find.text('Simular Paso (10 m)');
      expect(advanceButton, findsOneWidget);

      await tester.tap(advanceButton);
      await tester.pump();

      expect(updatedLocation, isNotNull);
      expect(updatedLocation!.latitude, greaterThan(testRoute.points.first.latitude));
    });

    testWidgets('Aligns camera heading when navigation compass is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CampusWalk3DView(
            route: testRoute,
            buildings: const [buildingA, buildingB],
            initialLocation: testRoute.points.first,
            initialHeading: 90.0,
          ),
        ),
      );

      await tester.pump();

      final compassFab = find.byType(FloatingActionButton);
      expect(compassFab, findsOneWidget);

      await tester.tap(compassFab);
      await tester.pump();
    });

    testWidgets('Triggers destination reached callback at the end of route', (tester) async {
      var arrived = false;

      await tester.pumpWidget(
        MaterialApp(
          home: CampusWalk3DView(
            route: testRoute,
            buildings: const [buildingA, buildingB],
            initialLocation: testRoute.points[2],
            initialHeading: 0.0,
            onDestinationReached: () => arrived = true,
          ),
        ),
      );

      await tester.pump();

      final advanceButton = find.text('+30 m');
      expect(advanceButton, findsOneWidget);
      await tester.tap(advanceButton);
      await tester.pump();
      await tester.tap(advanceButton);
      await tester.pump();

      expect(arrived, isTrue);
    });
  });
}
