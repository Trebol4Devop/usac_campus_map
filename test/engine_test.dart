import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  late CampusDataRepository repository;
  late RouteEngine routeEngine;
  late SearchEngine searchEngine;

  setUp(() {
    repository = CampusDataRepository();

    final boundaryJson = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                [-90.5560, 14.5760],
                [-90.5440, 14.5760],
                [-90.5440, 14.5910],
                [-90.5560, 14.5910],
                [-90.5560, 14.5760],
              ]
            ]
          }
        }
      ]
    };

    final buildingsJson = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {
            'id': 't-3',
            'name': 'Edificio T-3 (Facultad de Ingeniería)',
            'code': 'T-3',
            'category': 'faculty',
            'floors_count': 4,
            'entrances': [
              {
                'id': 't3-east',
                'name': 'Puerta Este',
                'lat': 14.587744,
                'lng': -90.552960,
                'nearest_node_id': 'n_t3_east',
              },
              {
                'id': 't3-west',
                'name': 'Puerta Oeste',
                'lat': 14.587760,
                'lng': -90.553520,
                'nearest_node_id': 'n_t3_west',
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
            'id': 'iglu',
            'name': 'Bienestar Estudiantil (El Iglú)',
            'code': 'IGLU',
            'category': 'administrative',
            'floors_count': 2,
            'entrances': [
              {
                'id': 'iglu-main',
                'name': 'Puerta Iglú',
                'lat': 14.586299,
                'lng': -90.553200,
                'nearest_node_id': 'n_iglu',
              }
            ]
          },
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                [-90.5535, 14.5864],
                [-90.5532, 14.5864],
                [-90.5532, 14.5861],
                [-90.5535, 14.5861],
                [-90.5535, 14.5864],
              ]
            ]
          }
        }
      ]
    };

    final graphJson = {
      'nodes': [
        {'id': 'n_t3_east', 'lat': 14.587744, 'lng': -90.552960},
        {'id': 'n_t3_west', 'lat': 14.587760, 'lng': -90.553520},
        {'id': 'n_mid', 'lat': 14.587000, 'lng': -90.553200},
        {'id': 'n_iglu', 'lat': 14.586299, 'lng': -90.553200},
      ],
      'edges': [
        {'source': 'n_t3_east', 'target': 'n_mid', 'weight': 80.0, 'type': 'walkway'},
        {'source': 'n_mid', 'target': 'n_t3_east', 'weight': 80.0, 'type': 'walkway'},
        {'source': 'n_t3_west', 'target': 'n_mid', 'weight': 85.0, 'type': 'walkway'},
        {'source': 'n_mid', 'target': 'n_t3_west', 'weight': 85.0, 'type': 'walkway'},
        {'source': 'n_mid', 'target': 'n_iglu', 'weight': 75.0, 'type': 'covered'},
        {'source': 'n_iglu', 'target': 'n_mid', 'weight': 75.0, 'type': 'covered'},
      ]
    };

    final poisJson = {
      'buildings': [
        {
          'building_id': 't-3',
          'floors': [
            {
              'level': 1,
              'name': 'Nivel 1',
              'pois': [
                {
                  'id': 'atm-5b',
                  'name': 'Cajero 5B Ingeniería',
                  'code': 'ATM-5B',
                  'floor_level': 1,
                  'category': 'cajeros',
                  'aliases': ['5B', 'Cajero 5B', 'ATM'],
                }
              ]
            },
            {
              'level': 2,
              'name': 'Nivel 2',
              'pois': [
                {
                  'id': 'salon-201',
                  'name': 'Salón 201',
                  'code': '201',
                  'floor_level': 2,
                  'category': 'aulas',
                  'aliases': ['Salon 201', 'Aula 201'],
                }
              ]
            }
          ]
        }
      ]
    };

    repository.loadFromJson(
      boundaryJson: boundaryJson,
      buildingsJson: buildingsJson,
      graphJson: graphJson,
      poisJson: poisJson,
    );

    routeEngine = RouteEngine(repository: repository);
    searchEngine = SearchEngine(repository: repository);
  });

  group('CampusDataRepository tests', () {
    test('loads and parses all entities properly', () {
      expect(repository.isLoaded, isTrue);
      expect(repository.boundary.length, equals(5));
      expect(repository.buildings.length, equals(2));
      expect(repository.buildingsById.containsKey('t-3'), isTrue);
      expect(repository.nodes.length, equals(4));
      expect(repository.edges.length, equals(6));
      expect(repository.allPois.length, equals(2));
    });
  });

  group('RouteEngine tests', () {
    test('routes to building entrance rather than center', () {
      const origin = LatLng(14.586299, -90.553200);
      final route = routeEngine.findRoute(
        origin: origin,
        destinationId: 't-3',
        mode: NavigationMode.pedestrian,
      );

      expect(route, isNotNull);
      expect(route!.totalDistance, greaterThan(0));
      expect(
        route.nodes.last.id == 'n_t3_east' || route.nodes.last.id == 'n_t3_west',
        isTrue,
      );
    });

    test('routes from POI to POI via their respective building entrances', () {
      const origin = LatLng(14.586299, -90.553200);
      final route = routeEngine.findRoute(
        origin: origin,
        destinationId: 'atm-5b',
        mode: NavigationMode.covered,
      );

      expect(route, isNotNull);
    });
  });

  group('SearchEngine tests', () {
    test('resolves Sancarlista aliases accurately', () {
      final igluResults = searchEngine.search('El Iglú');
      expect(igluResults.isNotEmpty, isTrue);
      expect(igluResults.first.id, equals('iglu'));

      final t3Results = searchEngine.search('T-3');
      expect(t3Results.isNotEmpty, isTrue);
      expect(t3Results.first.id, equals('t-3'));
    });

    test('fuzzy search matches despite minor typographical errors', () {
      final fuzzyResults = searchEngine.search('Ingenieria');
      expect(fuzzyResults.any((r) => r.id == 't-3'), isTrue);

      final typoResults = searchEngine.search('Ingeniria');
      expect(typoResults.any((r) => r.id == 't-3'), isTrue);
    });

    test('searches indoor POIs and respects category filters', () {
      final atmResults = searchEngine.search('5B');
      expect(atmResults.any((r) => r.id == 'atm-5b'), isTrue);

      final filtered = searchEngine.search('', category: 'cajeros');
      expect(filtered.every((r) => r.category == 'cajeros'), isTrue);
    });
  });
}
