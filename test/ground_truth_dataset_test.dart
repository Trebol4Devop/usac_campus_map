import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CampusDataRepository repository;
  late RouteEngine routeEngine;
  late SearchEngine searchEngine;

  setUp(() {
    final boundaryJson = jsonDecode(
      File('assets/geojson/usac_boundary.geojson').readAsStringSync(),
    ) as Map<String, dynamic>;
    final buildingsJson = jsonDecode(
      File('assets/geojson/usac_buildings.geojson').readAsStringSync(),
    ) as Map<String, dynamic>;
    final graphJson = jsonDecode(
      File('assets/graph/campus_graph.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final poisJson = jsonDecode(
      File('assets/pois/usac_pois_and_indoors.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    repository = CampusDataRepository();
    repository.loadFromJson(
      boundaryJson: boundaryJson,
      buildingsJson: buildingsJson,
      graphJson: graphJson,
      poisJson: poisJson,
    );

    routeEngine = RouteEngine(repository: repository);
    searchEngine = SearchEngine(repository: repository);
  });

  test('ground truth assets load successfully and populate data structures', () {
    expect(repository.isLoaded, isTrue);
    expect(repository.boundary.length, greaterThan(20));
    expect(repository.buildings.length, greaterThanOrEqualTo(100));
    expect(repository.nodes.length, greaterThan(500));
    expect(repository.edges.length, greaterThan(1000));
    expect(repository.allPois.length, greaterThanOrEqualTo(20));
  });

  test('search engine correctly resolves authentic campus entities and aliases', () {
    final queries = [
      'T-3',
      'El Iglú',
      'Rectoría',
      'Cajero 5B',
      'S-12',
      'Arqui',
      'Biblioteca',
      'Auditorio',
      'Los Cubos',
      'Plaza de los Mártires',
    ];
    for (final q in queries) {
      final results = searchEngine.search(q);
      expect(results, isNotEmpty, reason: 'Failed search for $q');
    }
  });

  test('T-3 has complete cardinal entrances and route engine picks optimal doors', () {
    final t3 = repository.buildingsById['t-3'];
    expect(t3, isNotNull);
    expect(t3!.entrances.length, greaterThanOrEqualTo(4));

    final routeEast = routeEngine.findRouteBetweenBuildings(
      originBuildingId: 't-3',
      destinationBuildingId: 'rectoria',
    );
    expect(routeEast, isNotNull);
    expect(routeEast!.points.first.longitude, greaterThan(-90.5532));

    final routeWest = routeEngine.findRouteBetweenBuildings(
      originBuildingId: 't-3',
      destinationBuildingId: 't-1',
    );
    expect(routeWest, isNotNull);
    expect(routeWest!.points.first.longitude, lessThan(-90.5533));
  });

  test('landmarks have realistic geometries and valid entrances', () {
    final plaza = repository.buildingsById['plaza-martires'];
    expect(plaza, isNotNull);
    expect(plaza!.polygon.length, greaterThan(10));
    expect(plaza.entrances, isNotEmpty);

    final cubos = repository.buildingsById['los_cubos'];
    expect(cubos, isNotNull);
    expect(cubos!.polygon.length, greaterThanOrEqualTo(4));
    expect(cubos.entrances, isNotEmpty);
  });

  test('route engine computes valid pedestrian routes across real campus buildings', () {
    final pairs = [
      ['t-1', 's-12'],
      ['t-3', 'rectoria'],
      ['biblio-central', 's-2'],
      ['t-8', 'iglu'],
      ['t-4', 's-3'],
      ['m-1', 't-1'],
      ['s-12', 'plaza-martires'],
      ['los_cubos', 't-3'],
    ];

    for (final pair in pairs) {
      final b1 = repository.buildingsById[pair[0]];
      final b2 = repository.buildingsById[pair[1]];
      expect(b1, isNotNull, reason: 'Building ${pair[0]} not found');
      expect(b2, isNotNull, reason: 'Building ${pair[1]} not found');

      final route = routeEngine.findRouteBetweenBuildings(
        originBuildingId: pair[0],
        destinationBuildingId: pair[1],
        mode: NavigationMode.pedestrian,
      );

      expect(route, isNotNull, reason: 'Route from ${pair[0]} to ${pair[1]} should exist');
      expect(route!.totalDistance, greaterThan(5.0));
      expect(route.points.length, greaterThan(2));
      expect(route.steps, isNotEmpty);
    }
  });

  test('route engine supports multimodal navigation over real graph', () {
    final pedRoute = routeEngine.findRouteBetweenBuildings(
      originBuildingId: 't-3',
      destinationBuildingId: 's-12',
      mode: NavigationMode.pedestrian,
    );
    final accRoute = routeEngine.findRouteBetweenBuildings(
      originBuildingId: 't-3',
      destinationBuildingId: 's-12',
      mode: NavigationMode.accessible,
    );

    expect(pedRoute, isNotNull);
    expect(accRoute, isNotNull);
    expect(accRoute!.hasStairs, isFalse);
  });

  test('ground truth contains S-1, M-4, green areas, and parking facilities', () {
    final s1 = repository.buildingsById['s-1'];
    expect(s1, isNotNull);
    expect(s1!.name, contains('S-1'));
    expect(s1.polygon.length, greaterThanOrEqualTo(4));

    final m4 = repository.buildingsById['m-4'];
    expect(m4, isNotNull);
    expect(m4!.name, contains('M-4'));
    expect(m4.polygon.length, greaterThanOrEqualTo(4));

    final m5 = repository.buildingsById['m-5'];
    expect(m5, isNotNull);
    expect(m5!.name, contains('M-5'));

    final ranchitos = repository.buildingsById['los_ranchitos'];
    expect(ranchitos, isNotNull);
    expect(ranchitos!.category, equals('green_area'));

    final huerto = repository.buildingsById['el_huerto'];
    expect(huerto, isNotNull);
    expect(huerto!.category, equals('green_area'));

    final parqueoArqui = repository.buildingsById['parqueo_arquitectura'];
    expect(parqueoArqui, isNotNull);
    expect(parqueoArqui!.category, equals('parking'));

    final parqueoIng = repository.buildingsById['parqueo_ingenieria'];
    expect(parqueoIng, isNotNull);
    expect(parqueoIng!.category, equals('parking'));

    final t1 = repository.buildingsById['t-1'];
    expect(t1, isNotNull);
    expect(t1!.polygon.length, greaterThanOrEqualTo(4));

    final t5 = repository.buildingsById['t-5'];
    expect(t5, isNotNull);
    expect(t5!.polygon.length, greaterThanOrEqualTo(4));

    final s6 = repository.buildingsById['s-6'];
    expect(s6, isNotNull);

    final s7 = repository.buildingsById['s-7'];
    expect(s7, isNotNull);

    final s11 = repository.buildingsById['s-11'];
    expect(s11, isNotNull);

    final garitaPetapaSearch = searchEngine.search('Garita Petapa');
    expect(garitaPetapaSearch, isNotEmpty);

    final garitaPerifericoSearch = searchEngine.search('Garita Periferico');
    expect(garitaPerifericoSearch, isNotEmpty);
  });

  test('controller dynamically recalculates route when navigation mode is switched', () {
    final controller = UsacCampusMapController(repository: repository);
    final origin = repository.buildingsById['t-3']!;
    final dest = repository.buildingsById['s-12']!;

    final initialRoute = controller.startRouteBetweenBuildings(
      origin: origin,
      destination: dest,
      mode: NavigationMode.pedestrian,
    );
    expect(initialRoute, isNotNull);
    expect(controller.navigationMode, equals(NavigationMode.pedestrian));

    controller.setNavigationMode(NavigationMode.accessible);
    expect(controller.navigationMode, equals(NavigationMode.accessible));
    expect(controller.currentRoute, isNotNull);
    expect(controller.currentRoute!.hasStairs, isFalse);
  });
}
