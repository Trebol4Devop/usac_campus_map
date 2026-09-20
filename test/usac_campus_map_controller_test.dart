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

class _FakeUsacCampusMapDelegate implements UsacCampusMapDelegate {
  LatLng? lastMovedCenter;
  double? lastMovedZoom;
  bool? lastMovedAnimate;
  LatLngBounds? lastFitBounds;
  CampusRoute? lastActiveRoute;
  String? lastHighlightedBuildingId;
  BuildingCategory? lastCategoryFilter;

  @override
  LatLng get currentCenter => const LatLng(14.587500, -90.551845);

  @override
  double get currentZoom => 16.5;

  @override
  LatLng? get currentUserLocation => const LatLng(14.587500, -90.551845);

  @override
  bool get isInsideCampus => true;

  @override
  void fitBounds(
    LatLngBounds bounds, {
    EdgeInsets padding = const EdgeInsets.all(40),
    bool animate = true,
  }) {
    lastFitBounds = bounds;
  }

  @override
  void moveCamera(LatLng center, double zoom, {bool animate = true}) {
    lastMovedCenter = center;
    lastMovedZoom = zoom;
    lastMovedAnimate = animate;
  }

  @override
  void setActiveRoute(CampusRoute? route) {
    lastActiveRoute = route;
  }

  @override
  void setCategoryFilter(BuildingCategory? category) {
    lastCategoryFilter = category;
  }

  @override
  void setHighlightedBuilding(String? buildingId) {
    lastHighlightedBuildingId = buildingId;
  }
}

void main() {
  group('UsacCampusMapController Unit Tests', () {
    late UsacCampusMapController controller;
    late _FakeUsacCampusMapDelegate delegate;

    setUp(() {
      controller = UsacCampusMapController();
      delegate = _FakeUsacCampusMapDelegate();
    });

    test('initial state has no attached delegate and null properties', () {
      expect(controller.isAttached, isFalse);
      expect(controller.highlightedBuildingId, isNull);
      expect(controller.currentRoute, isNull);
      expect(controller.categoryFilter, isNull);
      expect(controller.currentUserLocation, isNull);
      expect(controller.isInsideCampus, isFalse);
    });

    test('attach and detach correctly manage delegate state', () {
      controller.attach(delegate);
      expect(controller.isAttached, isTrue);
      expect(controller.currentUserLocation, isNotNull);
      expect(controller.isInsideCampus, isTrue);

      controller.detach();
      expect(controller.isAttached, isFalse);
    });

    test('focusBuilding moves camera and sets highlight', () {
      controller.attach(delegate);
      var notified = false;
      controller.addListener(() => notified = true);

      controller.focusBuilding('t-3', animate: true, zoom: 18.0);

      expect(notified, isTrue);
      expect(controller.highlightedBuildingId, equals('t-3'));
      expect(delegate.lastHighlightedBuildingId, equals('t-3'));
      expect(delegate.lastMovedCenter, equals(const LatLng(14.587794, -90.553240)));
      expect(delegate.lastMovedZoom, equals(18.0));
      expect(delegate.lastMovedAnimate, isTrue);
    });

    test('highlightBuilding and clearHighlight notify listeners', () {
      controller.attach(delegate);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.highlightBuilding('s-2');
      expect(controller.highlightedBuildingId, equals('s-2'));
      expect(delegate.lastHighlightedBuildingId, equals('s-2'));
      expect(notifications, equals(1));

      controller.clearHighlight();
      expect(controller.highlightedBuildingId, isNull);
      expect(delegate.lastHighlightedBuildingId, isNull);
      expect(notifications, equals(2));
    });

    test('startRoute and clearRoute manage navigation state', () {
      controller.attach(delegate);
      final dest = UsacCampusDataset.getById('biblio-central')!;
      const origin = LatLng(14.587794, -90.553240);

      var notified = false;
      controller.addListener(() => notified = true);

      final route = controller.startRoute(origin: origin, destination: dest);

      expect(route, isNotNull);
      expect(notified, isTrue);
      expect(controller.currentRoute, equals(route));
      expect(delegate.lastActiveRoute, equals(route));
      expect(delegate.lastFitBounds, isNotNull);

      controller.clearRoute();
      expect(controller.currentRoute, isNull);
      expect(delegate.lastActiveRoute, isNull);
    });

    test('startRouteBetweenBuildings calculates route across two campus buildings', () {
      controller.attach(delegate);
      final origin = UsacCampusDataset.getById('t-3')!;
      final dest = UsacCampusDataset.getById('m-1')!;

      final route = controller.startRouteBetweenBuildings(
        origin: origin,
        destination: dest,
      );

      expect(route, isNotNull);
      expect(controller.currentRoute, isNotNull);
      expect(route!.destination.id, equals('m-1'));
    });

    test('setCategoryFilter and clearCategoryFilter update delegate', () {
      controller.attach(delegate);
      controller.setCategoryFilter(BuildingCategory.faculty);

      expect(controller.categoryFilter, equals(BuildingCategory.faculty));
      expect(delegate.lastCategoryFilter, equals(BuildingCategory.faculty));

      controller.clearCategoryFilter();
      expect(controller.categoryFilter, isNull);
      expect(delegate.lastCategoryFilter, isNull);
    });

    test('recenterCampus moves camera to campus center', () {
      controller.attach(delegate);
      controller.recenterCampus();

      expect(delegate.lastMovedCenter, equals(UsacCampusDataset.campusCenter));
      expect(delegate.lastMovedZoom, equals(16.5));
    });

    test('zoomIn and zoomOut calculate clamped zoom levels', () {
      controller.attach(delegate);

      controller.zoomIn();
      expect(delegate.lastMovedZoom, equals(17.5));

      controller.zoomOut();
      expect(delegate.lastMovedZoom, equals(15.5));
    });
  });

  group('UsacCampusMap with Controller Widget Tests', () {
    testWidgets('attaches controller when widget mounts and detaches on dispose', (tester) async {
      final controller = UsacCampusMapController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UsacCampusMap(
              controller: controller,
              tileProvider: FakeTileProvider(),
              animateCameraTransitions: false,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(controller.isAttached, isTrue);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(controller.isAttached, isFalse);
    });

    testWidgets('programmatic route between buildings renders polyline and navigation card', (tester) async {
      final controller = UsacCampusMapController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UsacCampusMap(
              controller: controller,
              tileProvider: FakeTileProvider(),
              animateCameraTransitions: false,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final origin = UsacCampusDataset.getById('t-3')!;
      final destination = UsacCampusDataset.getById('biblio-central')!;

      controller.startRouteBetweenBuildings(
        origin: origin,
        destination: destination,
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Ruta a ${destination.name}'), findsOneWidget);
      expect(find.byType(PolylineLayer), findsOneWidget);

      await tester.tap(find.byTooltip('Cancelar ruta'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(controller.currentRoute, isNull);
      expect(find.text('Ruta a ${destination.name}'), findsNothing);
    });

    testWidgets('programmatic highlightBuilding renders highlighted marker with stars icon', (tester) async {
      final controller = UsacCampusMapController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UsacCampusMap(
              controller: controller,
              tileProvider: FakeTileProvider(),
              animateCameraTransitions: false,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      controller.highlightBuilding('t-3');
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.stars), findsOneWidget);
    });
  });
}
