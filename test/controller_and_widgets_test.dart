import 'package:flutter/material.dart' hide NavigationMode;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  late CampusDataRepository repository;

  setUp(() {
    repository = CampusDataRepository();
    repository.loadFromJson(
      boundaryJson: {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-90.556, 14.576],
                  [-90.544, 14.576],
                  [-90.544, 14.591],
                  [-90.556, 14.591],
                  [-90.556, 14.576],
                ]
              ]
            }
          }
        ]
      },
      buildingsJson: {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {
              'id': 't-3',
              'name': 'Edificio T-3',
              'code': 'T-3',
              'category': 'faculty',
              'floors_count': 4,
              'entrances': [
                {
                  'id': 'e1',
                  'name': 'Puerta 1',
                  'lat': 14.5877,
                  'lng': -90.5532,
                  'nearest_node_id': 'n1',
                }
              ]
            },
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-90.5535, 14.5879],
                  [-90.5529, 14.5879],
                  [-90.5529, 14.5876],
                  [-90.5535, 14.5876],
                  [-90.5535, 14.5879],
                ]
              ]
            }
          },
          {
            'type': 'Feature',
            'properties': {
              'id': 'biblio',
              'name': 'Biblioteca Central',
              'code': 'BIBLIO',
              'category': 'library',
              'floors_count': 3,
              'entrances': [
                {
                  'id': 'e2',
                  'name': 'Puerta Norte',
                  'lat': 14.5870,
                  'lng': -90.5519,
                  'nearest_node_id': 'n2',
                }
              ]
            },
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-90.5521, 14.5871],
                  [-90.5516, 14.5871],
                  [-90.5516, 14.5866],
                  [-90.5521, 14.5866],
                  [-90.5521, 14.5871],
                ]
              ]
            }
          }
        ]
      },
      graphJson: {
        'nodes': [
          {'id': 'n1', 'lat': 14.5877, 'lng': -90.5532},
          {'id': 'n2', 'lat': 14.5870, 'lng': -90.5519},
        ],
        'edges': [
          {'source': 'n1', 'target': 'n2', 'weight': 100.0, 'type': 'walkway'},
          {'source': 'n2', 'target': 'n1', 'weight': 100.0, 'type': 'walkway'},
        ]
      },
      poisJson: {
        'buildings': [
          {
            'building_id': 't-3',
            'floors': [
              {
                'level': 1,
                'name': 'Nivel 1',
                'pois': [
                  {
                    'id': 'p1',
                    'name': 'Cajero 5B',
                    'code': '5B',
                    'floor_level': 1,
                    'category': 'cajeros',
                  }
                ]
              }
            ]
          }
        ]
      },
    );
  });

  group('UsacCampusMapController tests', () {
    test('manages route, selection, and floor state correctly', () {
      final controller = UsacCampusMapController(repository: repository);
      expect(controller.buildings.length, equals(2));

      controller.selectBuilding('t-3');
      expect(controller.selectedBuilding?.id, equals('t-3'));
      expect(controller.selectedFloor, equals(1));

      controller.selectFloor(3);
      expect(controller.selectedFloor, equals(3));

      final route = controller.findRoute(
        origin: const LatLng(14.5877, -90.5532),
        destinationId: 'biblio',
        mode: NavigationMode.pedestrian,
      );
      expect(route, isNotNull);
      expect(controller.currentRoute, equals(route));

      controller.clearRoute();
      expect(controller.currentRoute, isNull);

      controller.dispose();
    });
  });

  group('Presentation widgets tests', () {
    testWidgets('FloorSelector renders levels and responds to taps', (tester) async {
      int selected = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FloorSelector(
                  floorsCount: 4,
                  selectedFloor: selected,
                  onFloorSelected: (level) {
                    setState(() => selected = level);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();
      expect(selected, equals(3));
    });

    testWidgets('TurnByTurnBanner displays route information and triggers close', (tester) async {
      bool closed = false;
      const testRoute = CampusRoute(
        points: [LatLng(14.587, -90.553), LatLng(14.588, -90.553)],
        nodes: [
          CampusNode(id: '1', location: LatLng(14.587, -90.553)),
          CampusNode(id: '2', location: LatLng(14.588, -90.553)),
        ],
        edges: [
          CampusEdge(source: '1', target: '2', weight: 110.0, type: 'walkway'),
        ],
        totalDistance: 110.0,
        estimatedTimeMinutes: 2.0,
        mode: NavigationMode.pedestrian,
        steps: [
          RouteStep(
            instruction: 'Camine hacia el norte',
            distance: 110.0,
            type: 'walkway',
            location: LatLng(14.587, -90.553),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TurnByTurnBanner(
              route: testRoute,
              onClose: () => closed = true,
            ),
          ),
        ),
      );

      expect(find.text('Camine hacia el norte'), findsOneWidget);
      expect(find.text('110 m'), findsOneWidget);
      expect(find.text('~2 min'), findsOneWidget);

      await tester.tap(find.byTooltip('Cerrar navegación'));
      expect(closed, isTrue);
    });

    testWidgets('PoiDetailSheet displays information and triggers navigation', (tester) async {
      NavigationMode? chosenMode;
      final building = repository.buildings.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PoiDetailSheet(
              building: building,
              currentFloor: 1,
              onNavigate: (mode) => chosenMode = mode,
            ),
          ),
        ),
      );

      expect(find.text('Edificio T-3'), findsOneWidget);
      expect(find.text('Cómo llegar / Trazar Ruta'), findsOneWidget);

      await tester.tap(find.text('Cómo llegar / Trazar Ruta'));
      expect(chosenMode, equals(NavigationMode.pedestrian));

      await tester.tap(find.byTooltip('Ruta Techada (Lluvia)'));
      expect(chosenMode, equals(NavigationMode.covered));
    });

    testWidgets('UsacCampusMap mounts properly with controller', (tester) async {
      final controller = UsacCampusMapController(repository: repository);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UsacCampusMap(
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.byType(UsacCampusMap), findsOneWidget);
      expect(find.byType(FlutterMap), findsOneWidget);

      controller.dispose();
    });
  });
}
